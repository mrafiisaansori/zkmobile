import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'catalog_cache.dart';
import 'failed_transactions_page.dart';
import 'main.dart';
import 'models.dart';
import 'offline_queue.dart';
import 'sheets.dart';
import 'shell.dart';
import 'theme.dart';
import 'widgets.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});
  @override
  State<PosPage> createState() => PosPageState();
}

class PosPageState extends State<PosPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _cart = Cart.i;
  Timer? _debounce;

  List<Produk> _produk = [];
  List<Kategori> _kategori = [];
  List<JenisBayar> _jenisBayar = [];
  TaxSetting? _tax;
  Qris? _qris;
  Object _activeKat = 'all';
  bool _loading = true, _loadingMore = false, _lastPage = false;
  int _page = 1;
  bool _shiftActive = true;
  int _offlinePending = 0;

  // Cache varian per produk agar tidak request berulang (padanan modCache di web).
  final Map<int, List<ModifierGroup>> _modCache = {};

  bool get _isPro => Session.isPro;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCart);
    _loadRefs();
    _loadProduk();
    _trySyncOffline();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _cart.removeListener(_onCart);
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onCart() => setState(() {});

  // Dipanggil shell setelah open bill dimuat ke keranjang.
  void refreshAfterBill() {
    if (_produk.isNotEmpty) _cart.hydrateImages(_produk);
    setState(() {});
  }

  Future<void> _loadRefs() async {
    final aktif = await Api.shiftActive();
    if (mounted) setState(() => _shiftActive = aktif);
    try {
      final k = await Api.kategori();
      final j = await Api.jenisBayar();
      final t = await Api.tax();
      final q = await Api.qris();
      if (mounted) {
        setState(() {
          _kategori = k;
          _jenisBayar = j;
          _tax = t;
          _qris = q;
        });
      }
      // Simpan buat fallback offline — tidak perlu tunggu (fire and forget).
      cacheKategori(k);
      cacheJenisBayar(j);
      cacheTax(t);
    } catch (e) {
      // Referensi opsional gagal dimuat (mis. offline) — pakai cache lokal
      // biar metode pembayaran & kategori tetap ada saat koneksi putus.
      if (isNetworkError(e)) {
        final k = await readCachedKategori();
        final j = await readCachedJenisBayar();
        final t = await readCachedTax();
        if (mounted) {
          setState(() {
            _kategori = k;
            _jenisBayar = j;
            _tax = t;
          });
        }
      }
    }
  }

  Future<void> _loadProduk({bool append = false}) async {
    setState(() => append ? _loadingMore = true : _loading = true);
    // Fallback cache cuma masuk akal untuk daftar "Semua" halaman pertama —
    // hasil pencarian/kategori spesifik yang gagal dimuat tetap tampil kosong.
    final isDefaultView = !append && _search.text.isEmpty && _activeKat == 'all';
    try {
      final page = append ? _page + 1 : 1;
      final res = await Api.produk(
          search: _search.text, categoryId: _activeKat, page: page);
      if (!mounted) return;
      setState(() {
        if (append) {
          final seen = _produk.map((p) => p.id).toSet();
          _produk.addAll(res.where((p) => !seen.contains(p.id)));
        } else {
          _produk = res;
        }
        _page = page;
        _lastPage = res.length < 30;
      });
      if (_cart.billMode) _cart.hydrateImages(_produk);
      if (isDefaultView) cacheProduk(res);
      _prefetchModifiers(res);
    } catch (e) {
      if (isDefaultView && isNetworkError(e)) {
        final cached = await readCachedProduk();
        if (mounted) {
          setState(() {
            _produk = cached;
            _page = 1;
            _lastPage = true;
          });
          if (cached.isNotEmpty) {
            toastOk(context, 'Offline — menampilkan katalog produk tersimpan terakhir');
          } else {
            toastError(context, e);
          }
        }
      } else if (mounted) {
        toastError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => append ? _loadingMore = false : _loading = false);
      }
    }
  }

  void _loadMore() {
    if (_loading || _loadingMore || _lastPage) return;
    _loadProduk(append: true);
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _loadProduk());
  }

  // Penjaga transaksi: blokir bila sesi kasir belum dibuka (sama seperti web).
  bool _requireShift() {
    if (_shiftActive) return true;
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
    if (ok == true && mounted) setState(() => _shiftActive = true);
  }

  // Fitur PRO: FREE dapat info upgrade, bukan error diam-diam.
  bool _requirePro(String fitur) {
    if (_isPro) return true;
    toastError(context, '$fitur hanya tersedia untuk paket PRO/BUSINESS.');
    return false;
  }

  // Nyicil ambil & simpan info varian tiap produk yang baru dimuat, di
  // background — supaya SEMUA produk (bukan cuma yang pernah ditap) bisa
  // langsung dimasukkan ke keranjang saat offline nanti, tanpa nunggu
  // panggilan API per-produk lebih dulu. Sengaja berurutan (bukan paralel)
  // biar tidak membanjiri server; berhenti diam-diam kalau gagal.
  Future<void> _prefetchModifiers(List<Produk> produk) async {
    for (final p in produk) {
      if (!mounted || _modCache.containsKey(p.id)) continue;
      try {
        final groups = await Api.modifierFor(p.id);
        if (!mounted) return;
        _modCache[p.id] = groups;
        cacheModifier(p.id, groups);
      } catch (_) {
        return; // biasanya berarti offline — hentikan, coba lagi lain kali
      }
    }
  }

  Future<List<ModifierGroup>> _modifierFor(Produk p) async {
    final cached = _modCache[p.id];
    if (cached != null) return cached;
    try {
      final groups = await Api.modifierFor(p.id);
      _modCache[p.id] = groups;
      cacheModifier(p.id, groups);
      return groups;
    } catch (e) {
      if (isNetworkError(e)) {
        final offline = await readCachedModifier(p.id);
        if (offline != null) {
          _modCache[p.id] = offline;
          return offline;
        }
      }
      rethrow;
    }
  }

  Future<void> _addToCart(Produk p) async {
    if (!_requireShift()) return;
    try {
      final groups = await _modifierFor(p);
      if (groups.isEmpty) {
        final res = _cart.addItem(p);
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
      final res = _cart.addLine(p, chosen);
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
      final p = await Api.byBarcode(code);
      await _addToCart(p);
      _search.clear();
      _loadProduk();
    } catch (_) {
      if (mounted) toastError(context, 'Produk barcode tidak ditemukan');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && !_shiftActive) {
      return HeroShell(child: SafeArea(top: false, bottom: false, child: _shiftGate()));
    }
    final tablet = isTablet(context);
    return HeroShell(
      child: SafeArea(
        top: false,
        bottom: false,
        child: tablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _productColumn(showCartBar: false)),
                  SizedBox(
                    width: 400,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      child: CartSheet(
                        embedded: true,
                        isPro: _isPro,
                        onCheckout: _openPayment,
                        onSaveBill: _saveBill,
                        onUpdateBill: _updateBill,
                        onCancelBill: _cancelBill,
                        onSplitBill: _openSplitBill,
                        onPickMember: _pickMember,
                      ),
                    ),
                  ),
                ],
              )
            : _productColumn(showCartBar: true),
      ),
    );
  }

  // Kolom kiri: banner + pencarian + kategori + grid produk. Di tablet dipakai
  // di sisi kiri Row (cart ada permanen di kanan), di ponsel isi build() penuh.
  Widget _productColumn({required bool showCartBar}) => Column(
        children: [
          const SizedBox(height: 16),
          if (_offlinePending > 0) _offlineBanner(),
          if (_cart.billMode) _billBanner(),
          _searchBar(),
          _categoryChips(),
          Expanded(
            child: _loading
                ? const ProductGridSkeleton()
                : _produk.isEmpty
                    ? const EmptyState(
                        title: 'Produk tidak ditemukan',
                        description: 'Coba kata kunci atau kategori lain.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: () => _loadProduk(),
                        child: GridView.builder(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(16, 4, 16,
                              showCartBar && _cart.items.isNotEmpty ? 92 : 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTablet(context) ? 4 : 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.80,
                          ),
                          itemCount: _produk.length + (_loadingMore ? 2 : 0),
                          itemBuilder: (_, i) => i >= _produk.length
                              ? const Center(
                                  child: SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: ZK.primary),
                                  ),
                                )
                              : ProductCard(
                                  produk: _produk[i],
                                  onAdd: () => _addToCart(_produk[i])),
                        ),
                      ),
          ),
          if (showCartBar && _cart.items.isNotEmpty) _cartBar(),
        ],
      );

  // Kasir belum buka sesi -> blokir seluruh POS, bukan cuma banner, sampai
  // kasnya dibuka (padanan shiftModalOpen blocking di web, dibuat lebih tegas
  // untuk mobile karena tidak ada modal yang bisa "Nanti" dulu).
  Widget _shiftGate() {
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
                  color: ZK.amber50.withValues(alpha: dark ? 0.15 : 1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_clock, size: 34, color: ZK.amber700),
            ),
            const SizedBox(height: 18),
            Text('Kasir Belum Dibuka',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : ZK.ink)),
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
                onPressed: _bukaSesi,
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Buka Kas Sekarang',
                    style: TextStyle(fontWeight: FontWeight.w800)),
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

  // Ringkasan bill yang sedang diedit (padanan blok billCtx di web).
  // Ada transaksi tunai tersimpan lokal, belum kekirim ke server.
  Widget _offlineBanner() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: InkWell(
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FailedTransactionsPage()));
            _trySyncOffline();
          },
          borderRadius: r12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: ZK.amber50, borderRadius: r12),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, size: 18, color: ZK.amber700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      '$_offlinePending transaksi belum tersinkron — ketuk untuk lihat & kirim ulang',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700, color: ZK.amber700)),
                ),
                const Icon(Icons.chevron_right, size: 18, color: ZK.amber700),
              ],
            ),
          ),
        ),
      );

  Widget _billBanner() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final b = _cart.bill!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r14,
        border: Border.all(color: dark ? ZK.lineDark : ZK.brand200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _pill(Icons.person, b.customerName.isEmpty ? 'Tanpa nama' : b.customerName,
                  ZK.primary, Colors.white),
              const SizedBox(width: 6),
              _pill(Icons.tag, 'Meja ${b.tableNo.isEmpty ? '-' : b.tableNo}',
                  dark ? ZK.primary.withValues(alpha: 0.18) : ZK.brand100, ZK.primary),
              const Spacer(),
              if (b.noBill != null)
                Text(b.noBill!,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white60 : ZK.slate600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editBillMeta,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Ubah data'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: ZK.primary,
                      side: const BorderSide(color: ZK.brand200),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _keluarBill,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Keluar bill'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: dark ? Colors.white70 : ZK.slate500,
                      side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(text,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      );

  Widget _searchBar() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _scanBarcode(),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: dark ? Colors.white : ZK.ink),
                  decoration: InputDecoration(
                    hintText: 'Cari produk atau scan barcode...',
                    hintStyle: TextStyle(
                        color: dark ? Colors.white38 : ZK.slate600, fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        size: 20, color: dark ? Colors.white54 : ZK.slate400),
                    filled: true,
                    fillColor: dark ? ZK.cardDark : Colors.white,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: r12,
                        borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: r12,
                        borderSide: BorderSide(color: ZK.primary, width: 1.6)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _scanBarcode,
                style: OutlinedButton.styleFrom(
                  backgroundColor: dark ? ZK.cardDark : Colors.white,
                  foregroundColor: ZK.primary,
                  side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                  shape: const RoundedRectangleBorder(borderRadius: r12),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Icon(Icons.qr_code_scanner, size: 20),
              ),
            ),
            // Tombol +member disembunyikan di tablet — panel keranjang di
            // sana sudah punya baris "Pilih member/customer" sendiri.
            if (_isPro && !isTablet(context)) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _pickMember,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: dark ? ZK.cardDark : Colors.white,
                    foregroundColor: _cart.member == null
                        ? (dark ? Colors.white70 : ZK.slate500)
                        : ZK.primary,
                    side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                    shape: const RoundedRectangleBorder(borderRadius: r12),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Icon(
                      _cart.member == null ? Icons.person_add_alt : Icons.person,
                      size: 20),
                ),
              ),
            ],
          ],
        ),
    );
  }

  Widget _categoryChips() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget chip(Object id, String label) {
      final active = _activeKat == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () {
            setState(() => _activeKat = id);
            _loadProduk();
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(999),
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
          for (final k in _kategori) chip(k.id, k.deskripsi),
        ],
      ),
    );
  }

  // Bar keranjang menempel di bawah grid (menggantikan aside di web).
  Widget _cartBar() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        padding: EdgeInsets.fromLTRB(
            12, 10, 12, 10 + MediaQuery.of(context).padding.bottom * 0),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          border: Border(top: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openCart,
                borderRadius: r12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                            color: dark ? ZK.primary.withValues(alpha: 0.18) : ZK.brand50,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_cart_outlined,
                            size: 18, color: ZK.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${_cart.count} item · lihat keranjang',
                                style: TextStyle(
                                    fontSize: 12, color: dark ? Colors.white70 : ZK.slate600)),
                            Text(rupiah(_cart.total),
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: dark ? Colors.white : ZK.ink)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: _openPayment,
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                child: Text(_cart.billMode ? 'Bayar' : 'Bayar Semua',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
    );
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
    final m = await showModalBottomSheet<Member?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberPickerSheet(selected: _cart.member),
    );
    if (m != null) _cart.setMember(m.id == -1 ? null : m);
  }

  void _openPayment() {
    if (!_requireShift()) return;
    if (_cart.items.isEmpty) return;
    if (_jenisBayar.isEmpty) {
      toastError(context, 'Metode pembayaran belum tersedia');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(
        jenisBayar: _jenisBayar,
        tax: _tax,
        qris: _qris,
        isPro: _isPro,
        onConfirm: _checkout,
        onSaveBill: _cart.billMode ? null : _saveBill,
      ),
    );
  }

  Future<CheckoutResult> _checkout(
      JenisBayar metode, int bayar, String keterangan) async {
    final bill = _cart.bill;
    final t = Tagihan.hitung(
        items: _cart.items,
        diskon: _cart.diskon,
        voucher: _cart.voucher?.diskon ?? 0,
        tax: _tax,
        isPro: _isPro);

    // Bayar open bill yang sudah ada (ID-nya sudah pasti valid di server,
    // beda dari BUAT bill baru offline yang tidak diberi ID sungguhan) — jadi
    // sama amannya diantre seperti checkout tunai biasa.
    if (bill != null) {
      final body = {
        'id_jenis_bayar': metode.id,
        'bayar': bayar,
        'diskon': _cart.diskon,
        if (keterangan.isNotEmpty) 'keterangan': keterangan,
      };
      try {
        final res = CheckoutResult.fromJson(await apiPost('/open-bill/${bill.id}/pay', body));
        _cart.clear();
        _loadProduk();
        return res;
      } catch (e) {
        if (metode.isTunai && isNetworkError(e)) {
          final res = await _queueOffline('/open-bill/${bill.id}/pay', body, t.total, bayar,
              label:
                  'Bayar ${bill.noBill ?? 'Bill #${bill.id}'} · ${_itemsLabel(_cart.items)}');
          _cart.clear();
          _loadProduk();
          return res;
        }
        rethrow;
      }
    }

    final body = Api.checkoutBody(
      items: _cart.items,
      idJenisBayar: metode.id,
      idUser: Session.user!.id,
      bayar: bayar,
      diskon: _cart.diskon,
      keterangan: keterangan,
      kodeVoucher: _cart.voucher?.kode,
      memberId: _cart.member?.id,
    );
    try {
      final res = CheckoutResult.fromJson(await apiPost('/penjualan/checkout', body));
      _cart.clear();
      _loadProduk();
      return res;
    } catch (e) {
      // Hanya tunai (bukan QRIS) yang aman diantre offline — QRIS butuh
      // gateway online beneran, gak bisa "disimpan lalu disinkron".
      if (metode.isTunai && isNetworkError(e)) {
        final res = await _queueOffline('/penjualan/checkout', body, t.total, bayar,
            label: _itemsLabel(_cart.items));
        _cart.clear();
        _loadProduk();
        return res;
      }
      rethrow;
    }
  }

  // Ringkasan produk buat ditampilkan di antrean/halaman Transaksi
  // Bermasalah, mis. "Nasi Goreng x2, Es Teh x1".
  String _itemsLabel(List<CartItem> items) =>
      items.map((i) => '${i.produk.nama} x${i.qty}').join(', ');

  // Catatan: sengaja TIDAK menyentuh cart/produk di sini — pemanggil (checkout
  // penuh vs split bill) punya cara beda-beda buat beresin cart-nya sendiri.
  Future<CheckoutResult> _queueOffline(
      String endpoint, Map<String, dynamic> body, int total, int bayar,
      {required String label}) async {
    await enqueueOfflineSale(endpoint, body, label);
    if (mounted) setState(() => _offlinePending++);
    return CheckoutResult.offlineDraft(total: total, bayar: bayar);
  }

  // Coba kirim ulang antrean offline (dipanggil tiap POS dibuka/refresh —
  // padanan auto-sync saat event 'online' di web).
  Future<void> _trySyncOffline() async {
    final pending = await getOfflineQueue();
    if (!mounted) return;
    setState(() => _offlinePending = pending.length);
    if (pending.isEmpty) return;
    final r = await flushOfflineQueue();
    if (!mounted) return;
    setState(() => _offlinePending = _offlinePending - r.synced - r.failed);
    if (r.synced > 0) toastOk(context, '${r.synced} transaksi offline berhasil disinkron');
    if (r.failed > 0) {
      toastError(context, '${r.failed} transaksi offline ditolak server — cek ulang manual');
    }
  }

  // ===== Open bill =====
  Future<void> _saveBill() async {
    if (!_requireShift() || !_requirePro('Simpan Bill')) return;
    if (_cart.items.isEmpty) return;
    final data = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BillFormSheet(),
    );
    if (data == null) return;
    final body = Api.billBody(
        data['customer'] ?? '', data['table'] ?? '', data['note'] ?? '', _cart.items);
    try {
      await apiPost('/open-bill', body);
      _cart.clear();
      if (!mounted) return;
      toastOk(context, 'Bill tersimpan');
      KasirShell.of(context).goToOpenBill();
    } catch (e) {
      if (isNetworkError(e)) {
        // Bill baru belum punya ID server — cukup diantre, tapi TIDAK akan
        // muncul di daftar Open Bill sampai berhasil disinkron.
        await enqueueOfflineSale('/open-bill', body, 'Bill baru · ${_itemsLabel(_cart.items)}');
        if (mounted) setState(() => _offlinePending++);
        _cart.clear();
        if (!mounted) return;
        toastOk(context, 'Offline — bill akan tersimpan otomatis saat online lagi');
        KasirShell.of(context).goToOpenBill();
        return;
      }
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _editBillMeta() async {
    final b = _cart.bill!;
    final data = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BillFormSheet(
          customer: b.customerName, table: b.tableNo, note: b.note),
    );
    if (data == null) return;
    _cart.setBillMeta(
        customer: data['customer'], table: data['table'], note: data['note']);
  }

  Future<void> _updateBill() async {
    final b = _cart.bill;
    if (b == null || _cart.items.isEmpty) return;
    try {
      await Api.updateBill(
          b.id, b.customerName, b.tableNo, b.note, _cart.items);
      if (!mounted) return;
      toastOk(context, 'Perubahan bill tersimpan');
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _cancelBill() async {
    final b = _cart.bill;
    if (b == null) return;
    final ok = await confirmDialog(context,
        title: 'Batalkan bill?',
        message: 'Bill ${b.noBill ?? ''} akan dibatalkan dan tidak bisa dibuka lagi.',
        danger: true);
    if (!ok) return;
    try {
      await Api.cancelBill(b.id);
      _cart.clear();
      if (!mounted) return;
      toastOk(context, 'Open bill dibatalkan');
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  void _keluarBill() {
    _cart.clear();
    setState(() {});
  }

  // ===== Split bill =====
  Future<void> _openSplitBill() async {
    if (!_requireShift() || !_requirePro('Split Bill')) return;
    if (_cart.items.isEmpty) return;
    if (_jenisBayar.isEmpty) {
      toastError(context, 'Metode pembayaran belum tersedia');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitBillSheet(
        jenisBayar: _jenisBayar,
        tax: _tax,
        qris: _qris,
        isPro: _isPro,
        onPay: _paySplit,
      ),
    );
    if (mounted) setState(() {});
  }

  // Bayar sebagian: mode bill -> pay-partial, transaksi biasa -> checkout item terpilih.
  Future<CheckoutResult> _paySplit(SplitPayload p) async {
    final bill = _cart.bill;
    CheckoutResult res;
    if (bill != null) {
      final items = [
        for (final e in p.perDetail.entries) {'id_open_bill_detail': e.key, 'qty': e.value}
      ];
      try {
        res = await Api.payBillPartial(
          bill.id,
          items: items,
          idJenisBayar: p.metode.id,
          bayar: p.bayar,
          payerName: p.payerName,
          keterangan: p.keterangan,
        );
        // Muat ulang sisa bill; bila lunas keranjang dikosongkan.
        if (res.billStatus == 'PAID') {
          _cart.clear();
        } else {
          _cart.loadBill(await Api.openBill(bill.id));
        }
      } catch (e) {
        if (p.metode.isTunai && isNetworkError(e)) {
          final total = p.items.fold<int>(0, (s, i) => s + i.total);
          res = await _queueOffline(
              '/open-bill/${bill.id}/pay-partial',
              {
                'items': items,
                'id_jenis_bayar': p.metode.id,
                'bayar': p.bayar,
                if (p.payerName.isNotEmpty) 'payer_name': p.payerName,
                if (p.keterangan.isNotEmpty) 'keterangan': p.keterangan,
              },
              total,
              p.bayar,
              label: 'Split bill ${p.payerName} · ${_itemsLabel(p.items)}');
          // Sisa bill tidak bisa dimuat ulang dari server saat offline —
          // kurangi qty lokal saja, sinkron final terjadi saat antrean terkirim.
          for (final e in p.perLine.entries) {
            final src = _cart.items.where((c) => c.lineId == e.key).firstOrNull;
            if (src != null) _cart.updateQty(src, src.qty - e.value);
          }
        } else {
          rethrow;
        }
      }
    } else {
      final body = Api.checkoutBody(
        items: p.items,
        idJenisBayar: p.metode.id,
        idUser: Session.user!.id,
        bayar: p.bayar,
        keterangan: p.keterangan,
      );
      try {
        res = CheckoutResult.fromJson(await apiPost('/penjualan/checkout', body));
      } catch (e) {
        if (p.metode.isTunai && isNetworkError(e)) {
          final total = p.items.fold<int>(0, (s, i) => s + i.total);
          res = await _queueOffline('/penjualan/checkout', body, total, p.bayar,
              label: 'Split bill ${p.payerName} · ${_itemsLabel(p.items)}');
        } else {
          rethrow;
        }
      }
      // Kurangi qty baris yang sudah dibayar dari keranjang.
      for (final e in p.perLine.entries) {
        final src = _cart.items.where((c) => c.lineId == e.key).firstOrNull;
        if (src != null) _cart.updateQty(src, src.qty - e.value);
      }
    }
    _loadProduk();
    return res;
  }
}
