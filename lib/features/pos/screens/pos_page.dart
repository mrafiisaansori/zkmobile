import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'failed_transactions_page.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../cubit/pos_catalog_cubit.dart';
import '../cubit/pos_catalog_state.dart';
import '../data/pos_repository.dart';
import '../models/tagihan.dart';
import '../widgets/bill_form_sheet.dart';
import '../widgets/buka_sesi_sheet.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/member_picker_sheet.dart';
import '../widgets/modifier_sheet.dart';
import '../widgets/payment_sheet.dart';
import '../widgets/split_bill_sheet.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});
  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _repo = PosRepository();
  Timer? _debounce;

  final PosCatalogCubit _catalog = PosCatalogCubit();
  final CheckoutCubit _checkoutCubit = CheckoutCubit();

  bool get _isPro => Session.isPro;

  @override
  void initState() {
    super.initState();
    _catalog.loadRefs();
    _catalog.loadProduk();
    _trySyncOffline();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _catalog.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    _catalog.close();
    _checkoutCubit.close();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _catalog.loadProduk());
  }

  // Penjaga transaksi: blokir bila sesi kasir belum dibuka (sama seperti web).
  bool _requireShift() {
    if (_catalog.state.shiftActive) return true;
    _bukaSesi();
    return false;
  }

  Future<void> _bukaSesi() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BukaSesiSheet(),
    );
    if (ok == true) _catalog.setShiftActive(true);
  }

  // Fitur PRO: FREE dapat info upgrade, bukan error diam-diam.
  bool _requirePro(String fitur) {
    if (_isPro) return true;
    toastError(context, '$fitur hanya tersedia untuk paket PRO/BUSINESS.');
    return false;
  }

  Future<void> _addToCart(Produk p) async {
    if (!_requireShift()) return;
    final cartCubit = context.read<CartCubit>();
    try {
      final groups = await _catalog.modifierFor(p);
      if (groups.isEmpty) {
        final res = cartCubit.addItem(p);
        if (!res.ok && mounted) toastError(context, res.message!);
        return;
      }
      if (!mounted) return;
      final chosen = await showModalBottomSheet<List<ModifierOption>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ModifierSheet(produk: p, groups: groups),
      );
      if (chosen == null) return;
      final res = cartCubit.addLine(p, chosen);
      if (!res.ok && mounted) toastError(context, res.message!);
    } catch (e) {
      if (!mounted) return;
      // Produk ini punya varian tapi belum pernah dibuka saat online, jadi
      // belum ada cache-nya — pesan teknis (SocketException dsb) diganti
      // yang manusiawi.
      if (isNetworkError(e)) {
        toastError(context,
            '${p.nama} punya varian yang belum tersimpan offline. Buka dulu produk ini sekali saat online.');
      } else {
        toastError(context, e);
      }
    }
  }

  Future<void> _scanBarcode() async {
    final code = _search.text.trim();
    if (code.isEmpty || !_requireShift()) return;
    try {
      final p = await _repo.byBarcode(code);
      await _addToCart(p);
      _search.clear();
      _catalog.loadProduk();
    } catch (_) {
      if (mounted) toastError(context, 'Produk barcode tidak ditemukan');
    }
  }

  // ===== Aksi keranjang =====
  void _openCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => CartSheet(
        isPro: _isPro,
        onCheckout: () {
          Navigator.pop(sheetCtx);
          _openPayment();
        },
        onSaveBill: () {
          Navigator.pop(sheetCtx);
          _saveBill();
        },
        onUpdateBill: () {
          Navigator.pop(sheetCtx);
          _updateBill();
        },
        onCancelBill: () {
          Navigator.pop(sheetCtx);
          _cancelBill();
        },
        onSplitBill: () {
          Navigator.pop(sheetCtx);
          _openSplitBill();
        },
        onPickMember: () {
          Navigator.pop(sheetCtx);
          _pickMember();
        },
      ),
    );
  }

  Future<void> _pickMember() async {
    if (!_requirePro('Member')) return;
    final cartCubit = context.read<CartCubit>();
    final m = await showModalBottomSheet<Member?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberPickerSheet(selected: cartCubit.state.member),
    );
    if (m != null) cartCubit.setMember(m.id == -1 ? null : m);
  }

  void _openPayment() {
    if (!_requireShift()) return;
    final cart = context.read<CartCubit>().state;
    if (cart.items.isEmpty) return;
    if (_catalog.state.jenisBayar.isEmpty) {
      toastError(context, 'Metode pembayaran belum tersedia');
      return;
    }
    final sheet = PaymentSheet(
      jenisBayar: _catalog.state.jenisBayar,
      tax: _catalog.state.tax,
      qris: _catalog.state.qris,
      isPro: _isPro,
      onConfirm: _checkout,
      onSaveBill: cart.billMode ? null : _saveBill,
      onPickMember: _isPro ? _pickMember : null,
    );
    if (isTablet(context)) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820, maxHeight: 600), child: sheet),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  Future<CheckoutResult> _checkout(JenisBayar metode, int bayar, String keterangan) async {
    final cartCubit = context.read<CartCubit>();
    final cart = cartCubit.state;
    final t = Tagihan.hitung(
        items: cart.items,
        diskon: cart.diskon,
        voucher: cart.voucher?.diskon ?? 0,
        tax: _catalog.state.tax,
        isPro: _isPro);
    final res = await _checkoutCubit.checkout(
      items: cart.items,
      bill: cart.bill,
      diskon: cart.diskon,
      metode: metode,
      bayar: bayar,
      keterangan: keterangan,
      total: t.total,
      idUser: Session.user!.id,
      voucher: cart.voucher,
      memberId: cart.member?.id,
    );
    cartCubit.clear();
    _catalog.loadProduk();
    return res;
  }

  // Coba kirim ulang antrean offline (dipanggil tiap POS dibuka/refresh —
  // padanan auto-sync saat event 'online' di web).
  Future<void> _trySyncOffline() async {
    final r = await _checkoutCubit.trySyncOffline();
    if (!mounted) return;
    if (r.synced > 0) toastOk(context, '${r.synced} transaksi offline berhasil disinkron');
    if (r.failed > 0) {
      toastError(context, '${r.failed} transaksi offline ditolak server: cek ulang manual');
    }
  }

  // ===== Open bill =====
  Future<void> _saveBill() async {
    if (!_requireShift() || !_requirePro('Simpan Bill')) return;
    final cartCubit = context.read<CartCubit>();
    if (cartCubit.state.items.isEmpty) return;
    final data = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Nama bill terisi otomatis dari member yang dipilih (masih bisa diubah).
      builder: (_) => BillFormSheet(customer: cartCubit.state.member?.nama ?? ''),
    );
    if (data == null) return;
    try {
      final result = await _checkoutCubit.saveBill(
        customer: data['customer'] ?? '',
        table: data['table'] ?? '',
        note: data['note'] ?? '',
        items: cartCubit.state.items,
      );
      cartCubit.clear();
      if (!mounted) return;
      toastOk(
          context,
          result == BillSaveResult.offline
              ? 'Offline: bill akan tersimpan otomatis saat online lagi'
              : 'Bill tersimpan');
      context.read<ShellCubit>().goToOpenBill();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _editBillMeta() async {
    final cartCubit = context.read<CartCubit>();
    final b = cartCubit.state.bill!;
    final data = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BillFormSheet(customer: b.customerName, table: b.tableNo, note: b.note),
    );
    if (data == null) return;
    cartCubit.setBillMeta(customer: data['customer'], table: data['table'], note: data['note']);
  }

  Future<void> _updateBill() async {
    final cartCubit = context.read<CartCubit>();
    final b = cartCubit.state.bill;
    if (b == null || cartCubit.state.items.isEmpty) return;
    try {
      await _checkoutCubit.updateBill(b.id, b.customerName, b.tableNo, b.note, cartCubit.state.items);
      if (!mounted) return;
      toastOk(context, 'Perubahan bill tersimpan');
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _cancelBill() async {
    final cartCubit = context.read<CartCubit>();
    final b = cartCubit.state.bill;
    if (b == null) return;
    final ok = await confirmDialog(context,
        title: 'Batalkan bill?',
        message: 'Bill ${b.noBill ?? ''} akan dibatalkan dan tidak bisa dibuka lagi.',
        danger: true);
    if (!ok) return;
    try {
      await _checkoutCubit.cancelBill(b.id);
      cartCubit.clear();
      if (!mounted) return;
      toastOk(context, 'Open bill dibatalkan');
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  void _keluarBill() => context.read<CartCubit>().clear();

  // ===== Split bill =====
  Future<void> _openSplitBill() async {
    if (!_requireShift() || !_requirePro('Split Bill')) return;
    final cartCubit = context.read<CartCubit>();
    if (cartCubit.state.items.isEmpty) return;
    if (_catalog.state.jenisBayar.isEmpty) {
      toastError(context, 'Metode pembayaran belum tersedia');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitBillSheet(
        jenisBayar: _catalog.state.jenisBayar,
        tax: _catalog.state.tax,
        qris: _catalog.state.qris,
        isPro: _isPro,
        onPay: _paySplit,
      ),
    );
  }

  // Bayar sebagian: mode bill -> pay-partial, transaksi biasa -> checkout item terpilih.
  Future<CheckoutResult> _paySplit(SplitPayload p) async {
    final cartCubit = context.read<CartCubit>();
    final bill = cartCubit.state.bill;
    final total = p.items.fold<int>(0, (s, i) => s + i.total);
    CheckoutResult res;
    if (bill != null) {
      final partialItems = [
        for (final e in p.perDetail.entries) {'id_open_bill_detail': e.key, 'qty': e.value}
      ];
      res = await _checkoutCubit.paySplit(
        bill: bill,
        partialItems: partialItems,
        checkoutItems: p.items,
        metode: p.metode,
        bayar: p.bayar,
        payerName: p.payerName,
        keterangan: p.keterangan,
        total: total,
        idUser: Session.user!.id,
      );
      if (res.offline) {
        // Sisa bill tidak bisa dimuat ulang dari server saat offline —
        // kurangi qty lokal saja, sinkron final terjadi saat antrean terkirim.
        for (final e in p.perLine.entries) {
          final src = cartCubit.state.items.where((c) => c.lineId == e.key).firstOrNull;
          if (src != null) cartCubit.updateQty(src, src.qty - e.value);
        }
      } else if (res.billStatus == 'PAID') {
        cartCubit.clear();
      } else {
        cartCubit.loadBill(await _checkoutCubit.reloadBill(bill.id));
      }
    } else {
      res = await _checkoutCubit.paySplit(
        bill: null,
        partialItems: const [],
        checkoutItems: p.items,
        metode: p.metode,
        bayar: p.bayar,
        payerName: p.payerName,
        keterangan: p.keterangan,
        total: total,
        idUser: Session.user!.id,
      );
      // Kurangi qty baris yang sudah dibayar dari keranjang.
      for (final e in p.perLine.entries) {
        final src = cartCubit.state.items.where((c) => c.lineId == e.key).firstOrNull;
        if (src != null) cartCubit.updateQty(src, src.qty - e.value);
      }
    }
    _catalog.loadProduk();
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _catalog),
        BlocProvider.value(value: _checkoutCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          // Toast satu-kali dari PosCatalogCubit (gagal muat referensi/produk,
          // atau fallback cache offline berhasil) — padanan toastError/toastOk
          // yang dulu dipanggil langsung di dalam _loadProduk/_loadRefs.
          BlocListener<PosCatalogCubit, PosCatalogState>(
            listenWhen: (p, c) =>
                (c.error != null && c.error != p.error) || (c.info != null && c.info != p.info),
            listener: (context, state) {
              if (state.error != null) toastError(context, state.error!);
              if (state.info != null) toastOk(context, state.info!);
            },
          ),
          // Produk baru dimuat sementara sedang mengedit bill -> lengkapi foto
          // item bill yang belum punya (padanan `if (_cart.billMode)
          // _cart.hydrateImages(_produk);` di _loadProduk lama).
          BlocListener<PosCatalogCubit, PosCatalogState>(
            listenWhen: (p, c) => !identical(p.produk, c.produk),
            listener: (context, state) {
              final cartCubit = context.read<CartCubit>();
              if (cartCubit.state.billMode) cartCubit.hydrateImages(state.produk);
            },
          ),
          // Bill baru dimuat ke keranjang (dari Open Bill, sebelum
          // ShellCubit.openPos() pindah ke tab ini) -> lengkapi foto dari
          // produk yang sudah ada. Padanan `refreshAfterBill()` lama, yang
          // dulu dipanggil manual lewat GlobalKey reach-through dari shell;
          // sekarang PosPage bereaksi sendiri ke CartCubit (lihat catatan
          // desain di shell_cubit.dart).
          BlocListener<CartCubit, CartState>(
            listenWhen: (p, c) => c.bill != null && p.bill?.id != c.bill?.id,
            listener: (context, state) =>
                context.read<CartCubit>().hydrateImages(_catalog.state.produk),
          ),
        ],
        child: _PosView(this),
      ),
    );
  }
}

// Bagian yang benar-benar reaktif (baca PosCatalogCubit/CartCubit/CheckoutCubit
// lewat context.watch) dipisah dari _PosPageState supaya context yang dipakai
// watch adalah context DI BAWAH MultiBlocProvider di atas, bukan context milik
// PosPage sendiri (yang berada di ATAS provider itu dan tidak bisa melihatnya).
class _PosView extends StatelessWidget {
  final _PosPageState pos;
  const _PosView(this.pos);

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<PosCatalogCubit>().state;
    final cart = context.watch<CartCubit>().state;
    final checkout = context.watch<CheckoutCubit>().state;

    if (!catalog.loading && !catalog.shiftActive) {
      return HeroShell(child: SafeArea(top: false, bottom: false, child: _shiftGate(context)));
    }
    final tablet = isTablet(context);
    return HeroShell(
      child: SafeArea(
        top: false,
        bottom: false,
        child: tablet
            ? LayoutBuilder(builder: (context, c) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _productColumn(context, catalog, cart, checkout, showCartBar: false)),
                  SizedBox(
                    // 800px → 360, 1280 → 410, 1600+ → 440.
                    width: (c.maxWidth * 0.32).clamp(360.0, 440.0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      child: CartSheet(
                        embedded: true,
                        isPro: pos._isPro,
                        onCheckout: pos._openPayment,
                        onSaveBill: pos._saveBill,
                        onUpdateBill: pos._updateBill,
                        onCancelBill: pos._cancelBill,
                        onSplitBill: pos._openSplitBill,
                        onPickMember: pos._pickMember,
                      ),
                    ),
                  ),
                ],
              ))
            : _productColumn(context, catalog, cart, checkout, showCartBar: true),
      ),
    );
  }

  // Kolom kiri: banner + pencarian + kategori + grid produk. Di tablet dipakai
  // di sisi kiri Row (cart ada permanen di kanan), di ponsel isi build() penuh.
  Widget _productColumn(
          BuildContext context, PosCatalogState catalog, CartState cart, CheckoutState checkout,
          {required bool showCartBar}) =>
      Column(
        children: [
          const SizedBox(height: 16),
          if (cart.billMode) _billBanner(context, cart),
          _searchBar(context, checkout.offlinePending),
          _categoryChips(context, catalog),
          Expanded(
            child: catalog.loading
                ? const ProductGridSkeleton()
                : catalog.produk.isEmpty
                    ? const EmptyState(
                        title: 'Produk tidak ditemukan',
                        description: 'Coba kata kunci atau kategori lain.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: () => pos._catalog.loadProduk(),
                        child: GridView.builder(
                          controller: pos._scroll,
                          // Bar keranjang ada di bawah Column (tidak menimpa grid),
                          // jadi padding bawah cukup 16.
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          gridDelegate: isTablet(context)
                              ? const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 180,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.80,
                                )
                              : const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.80,
                                ),
                          itemCount: catalog.produk.length + (catalog.loadingMore ? 2 : 0),
                          itemBuilder: (_, i) => i >= catalog.produk.length
                              ? const Center(
                                  child: SizedBox(
                                    height: 22,
                                    width: 22,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2, color: ZK.primary),
                                  ),
                                )
                              : ProductCard(
                                  produk: catalog.produk[i],
                                  onAdd: () => pos._addToCart(catalog.produk[i])),
                        ),
                      ),
          ),
          if (showCartBar && cart.items.isNotEmpty) _cartBar(context, cart),
        ],
      );

  // Kasir belum buka sesi -> blokir seluruh POS, bukan cuma banner, sampai
  // kasnya dibuka (padanan shiftModalOpen blocking di web, dibuat lebih tegas
  // untuk mobile karena tidak ada modal yang bisa "Nanti" dulu).
  Widget _shiftGate(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                  color: ZK.amber50.withValues(alpha: dark ? 0.15 : 1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_clock, size: 34, color: ZK.amber700),
            ),
            const SizedBox(height: 18),
            Text('Kasir Belum Dibuka',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
            const SizedBox(height: 8),
            Text(
                'Buka sesi kasir dulu sebelum mulai melayani transaksi, supaya penjualanmu tercatat dan bisa dicocokkan saat tutup kasir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: dark ? Colors.white70 : ZK.slate500, height: 1.4)),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: pos._bukaSesi,
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Buka Kas Sekarang', style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ada transaksi tunai tersimpan lokal, belum kekirim ke server — chip kecil
  // di ujung kolom pencarian.
  Widget _offlineChip(BuildContext context, int pending) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FailedTransactionsPage()));
            pos._trySyncOffline();
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: softBg(ZK.amber700, ZK.amber50, Theme.of(context).brightness == Brightness.dark), borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 14, color: ZK.amber700),
                const SizedBox(width: 4),
                Text('$pending',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ZK.amber700)),
              ],
            ),
          ),
        ),
      );

  // Ringkasan bill yang sedang diedit (padanan blok billCtx di web) — 1 baris.
  Widget _billBanner(BuildContext context, CartState cart) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final b = cart.bill!;
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r12,
        border: Border.all(color: dark ? ZK.lineDark : ZK.brand200),
      ),
      child: Row(
        children: [
          Flexible(
            child: _pill(Icons.person, b.customerName.isEmpty ? 'Tanpa nama' : b.customerName,
                ZK.primary, Colors.white),
          ),
          const SizedBox(width: 6),
          _pill(Icons.tag, 'Meja ${b.tableNo.isEmpty ? '-' : b.tableNo}',
              dark ? ZK.primary.withValues(alpha: 0.18) : ZK.brand100, ZK.primary),
          const Spacer(),
          if (b.noBill != null)
            Text(b.noBill!,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: dark ? Colors.white60 : ZK.slate600)),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: dark ? Colors.white70 : ZK.slate600),
            onSelected: (v) => v == 'edit' ? pos._editBillMeta() : pos._keluarBill(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Ubah data')),
              PopupMenuItem(value: 'exit', child: Text('Keluar bill')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            ),
          ],
        ),
      );

  Widget _searchBar(BuildContext context, int offlinePending) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: pos._search,
                onChanged: pos._onSearchChanged,
                onSubmitted: (_) => pos._scanBarcode(),
                textInputAction: TextInputAction.search,
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                decoration: InputDecoration(
                  hintText: 'Cari produk atau scan barcode...',
                  hintStyle: TextStyle(color: dark ? Colors.white60 : ZK.slate600, fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20, color: dark ? Colors.white60 : ZK.slate400),
                  suffixIcon: offlinePending > 0 ? _offlineChip(context, offlinePending) : null,
                  suffixIconConstraints: const BoxConstraints(minHeight: 24),
                  filled: true,
                  fillColor: dark ? ZK.cardDark : Colors.white,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: r12, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: r12, borderSide: BorderSide(color: ZK.primary, width: 1.6)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: OutlinedButton(
              onPressed: pos._scanBarcode,
              style: OutlinedButton.styleFrom(
                backgroundColor: dark ? ZK.cardDark : Colors.white,
                foregroundColor: ZK.primary,
                side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                shape: const RoundedRectangleBorder(borderRadius: r12),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.qr_code_scanner, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips(BuildContext context, PosCatalogState catalog) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget chip(Object id, String label) {
      final active = catalog.activeKat == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => pos._catalog.setCategory(id),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        children: [
          chip('all', 'Semua'),
          for (final k in catalog.kategori) chip(k.id, k.deskripsi),
        ],
      ),
    );
  }

  // Bar keranjang menempel di bawah grid (menggantikan aside di web).
  Widget _cartBar(BuildContext context, CartState cart) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      margin: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
      padding: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : ZK.ink,
        borderRadius: r14,
        border: dark ? Border.all(color: ZK.lineDark) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: pos._openCart,
              borderRadius: r14,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      height: 22,
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: ZK.accent, borderRadius: BorderRadius.circular(11)),
                      child: Text('${cart.count}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            child: Text(rupiah(cart.total),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          const Text('Lihat keranjang',
                              style: TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: pos._openPayment,
              style: FilledButton.styleFrom(
                  backgroundColor: ZK.primary,
                  minimumSize: const Size(112, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(borderRadius: r12)),
              child: Text(cart.billMode ? 'Bayar' : 'Bayar Semua',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
