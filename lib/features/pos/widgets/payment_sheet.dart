import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../data/pos_repository.dart';
import '../models/cart_item.dart';
import '../models/tagihan.dart';
import '../../../shared/widgets/sheet_common.dart';
import 'success_sheet.dart';
import 'total_card.dart';

// ===== Pembayaran (padanan components/pos/PaymentModal.tsx) =====
class PaymentSheet extends StatefulWidget {
  final List<JenisBayar> jenisBayar;
  final TaxSetting? tax;
  final Qris? qris;
  final bool isPro;
  final Future<CheckoutResult> Function(JenisBayar, int, String) onConfirm;
  final VoidCallback? onSaveBill;
  // Pilih/ganti member (PRO). null = baris member tidak ditampilkan.
  final VoidCallback? onPickMember;
  const PaymentSheet({
    super.key,
    required this.jenisBayar,
    required this.tax,
    required this.qris,
    required this.isPro,
    required this.onConfirm,
    this.onSaveBill,
    this.onPickMember,
  });
  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  static const quick = [50000, 100000, 150000, 200000];
  final _repo = PosRepository();

  late JenisBayar _metode = widget.jenisBayar.first;
  final _bayar = TextEditingController();
  final _ket = TextEditingController();
  final _voucher = TextEditingController();
  bool _loading = false, _cekVoucher = false;

  // Satu sumber kebenaran untuk hitungan uang (lihat test/tagihan_test.dart).
  Tagihan _t(CartState cart) => Tagihan.hitung(
        items: cart.items,
        diskon: cart.diskon,
        voucher: cart.voucher?.diskon ?? 0,
        tax: widget.tax,
        isPro: widget.isPro,
      );
  int get _bayarNum => parseRupiah(_bayar.text);

  @override
  void dispose() {
    _bayar.dispose();
    _ket.dispose();
    _voucher.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final kode = _voucher.text.trim();
    if (kode.isEmpty) return;
    setState(() => _cekVoucher = true);
    final cartCubit = context.read<CartCubit>();
    try {
      final v = await _repo.validateVoucher(kode, cartCubit.state.subtotal);
      cartCubit.setVoucher(v);
      if (mounted) toastOk(context, 'Voucher ${v.kode} diterapkan');
    } catch (e) {
      cartCubit.setVoucher(null);
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _cekVoucher = false);
    }
  }

  Future<void> _submit() async {
    final cartCubit = context.read<CartCubit>();
    final total = _t(cartCubit.state).total;
    // Non-tunai (QRIS/transfer) dianggap bayar pas, sama seperti web.
    final bayar = _metode.isTunai ? _bayarNum : total;
    if (bayar < total) {
      toastError(context, 'Nominal bayar kurang dari total');
      return;
    }
    setState(() => _loading = true);
    try {
      final ket = _ket.text.trim().isEmpty && _metode.isQris
          ? 'Pembayaran QRIS Manual'
          : _ket.text.trim();
      final itemsSnapshot = List<CartItem>.from(cartCubit.state.items);
      final res = await widget.onConfirm(_metode, bayar, ket);
      if (!mounted) return;
      Navigator.pop(context);
      playSuccessSound();
      toastOk(
          context,
          res.offline
              ? 'Koneksi terputus: transaksi disimpan offline & otomatis dikirim saat online lagi.'
              : 'Transaksi ${res.noNota} berhasil diselesaikan');
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SuccessSheet(result: res, metode: _metode.nama, items: itemsSnapshot),
      );
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartCubit>().state;
    final t = _t(cart);
    final tablet = isTablet(context);
    final header = SheetHeader(
      title: 'Pembayaran',
      subtitle: 'Pilih metode & nominal',
      icon: Icons.payments_outlined,
    );
    final divider = Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100);

    // Tablet: dibuka sebagai Dialog (PosPage._openPayment), 2 kolom 5:6.
    if (tablet) {
      return Column(
        children: [
          header,
          divider,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.onPickMember != null) ...[_memberRow(dark, cart), const SizedBox(height: 12)],
                        TotalCard(t: t, tax: widget.tax),
                        const SizedBox(height: 16),
                        ..._metodeSection(dark, cols: 2),
                        const SizedBox(height: 16),
                        _extraSection(dark, cart),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _metode.isTunai
                                ? [
                                    ..._uangSection(dark, t.total, autofocus: false, quickCols: 4),
                                    const SizedBox(height: 12),
                                    _numpad(dark),
                                  ]
                                : [
                                    if (_metode.isQris) _qrisBox(),
                                    const SizedBox(height: 12),
                                    Text('Pembayaran non-tunai dianggap pas sesuai total.',
                                        style: TextStyle(
                                            fontSize: 13, color: dark ? Colors.white60 : ZK.slate500)),
                                  ],
                          ),
                        ),
                      ),
                      _footer(dark, t),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              divider,
              // Flexible (bukan Expanded) supaya sheet tetap setinggi isinya
              // bila muat, dan footer menempel di atas keyboard.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.onPickMember != null) ...[_memberRow(dark, cart), const SizedBox(height: 12)],
                      TotalCard(t: t, tax: widget.tax),
                      const SizedBox(height: 16),
                      ..._metodeSection(dark, cols: 3),
                      if (_metode.isQris) _qrisBox(),
                      if (_metode.isTunai) ...[
                        const SizedBox(height: 16),
                        // Tidak autofocus: keyboard baru muncul saat kasir mengetuk field.
                        ..._uangSection(dark, t.total, autofocus: false, quickCols: 3),
                      ],
                      const SizedBox(height: 16),
                      _extraSection(dark, cart),
                    ],
                  ),
                ),
              ),
              _footer(dark, t),
            ],
          ),
        ),
      ),
    );
  }

  // Member transaksi ini (sama dengan baris member di keranjang).
  Widget _memberRow(bool dark, CartState cart) {
    final m = cart.member;
    return InkWell(
      onTap: _loading ? null : widget.onPickMember,
      borderRadius: r12,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50,
          borderRadius: r12,
          border: Border.all(color: dark ? ZK.primary.withValues(alpha: 0.35) : ZK.brand100),
        ),
        child: Row(
          children: [
            Icon(m == null ? Icons.person_add_alt : Icons.person, size: 20, color: ZK.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m?.nama ?? 'Tanpa member',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.ink)),
                  Text(m == null ? 'Ketuk untuk pilih member' : 'Ketuk untuk ganti atau lepas member',
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: dark ? Colors.white60 : ZK.slate400),
          ],
        ),
      ),
    );
  }

  void _saveBill() {
    Navigator.pop(context);
    widget.onSaveBill!();
  }

  // Grid non-scroll dengan tinggi tile tetap.
  Widget _grid(int cols, double height, List<Widget> children) => GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, mainAxisExtent: height, mainAxisSpacing: 8, crossAxisSpacing: 8),
        children: children,
      );

  List<Widget> _metodeSection(bool dark, {required int cols}) => [
        const FieldLabel('Metode pembayaran'),
        _grid(cols, 48, [for (final j in widget.jenisBayar) _metodeTile(j, dark)]),
      ];

  List<Widget> _uangSection(bool dark, int total, {required bool autofocus, required int quickCols}) => [
        const FieldLabel('Uang diterima'),
        TextField(
          controller: _bayar,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          autofocus: autofocus,
          inputFormatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.slate900),
          decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
        ),
        const SizedBox(height: 10),
        _grid(quickCols, 44, [
          _quickBtn('Uang pas', dark, () => _setBayar(total)),
          for (final q in quick) _quickBtn(rupiah(q), dark, () => _setBayar(q)),
          _quickBtn('Hapus', dark, () => setState(_bayar.clear)),
        ]),
      ];

  void _setBayar(int v) => setState(() => _bayar.text = v == 0 ? '' : rupiahPlain(v));

  // Voucher & keterangan jarang dipakai → dilipat; terbuka sendiri bila voucher terpasang.
  late bool _extraOpen = context.read<CartCubit>().state.voucher != null;

  Widget _extraSection(bool dark, CartState cart) {
    final fg = dark ? Colors.white70 : ZK.slate700;
    return Container(
      decoration: BoxDecoration(
        borderRadius: r12,
        border: Border.all(color: dark ? ZK.lineDark : ZK.brand100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: r12,
            onTap: () => setState(() => _extraOpen = !_extraOpen),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 18, color: fg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          cart.voucher == null
                              ? 'Voucher & keterangan'
                              : 'Voucher ${cart.voucher!.kode} & keterangan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                    ),
                    Icon(_extraOpen ? Icons.expand_less : Icons.expand_more, color: fg),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: !_extraOpen
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FieldLabel('Kode voucher (opsional)'),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _voucher,
                                textCapitalization: TextCapitalization.characters,
                                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                                decoration: sheetInput('mis. DISKON10', dark: dark),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 47,
                              child: OutlinedButton(
                                onPressed: _cekVoucher ? null : _applyVoucher,
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: ZK.primary,
                                    side: const BorderSide(color: ZK.brand200),
                                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                                child: _cekVoucher
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: ZK.primary))
                                    : const Text('Pakai'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Keterangan (opsional)'),
                        TextField(
                            controller: _ket,
                            style: TextStyle(color: dark ? Colors.white : ZK.ink),
                            decoration: sheetInput('mis. pesanan take away', dark: dark)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Footer selalu terlihat: kembalian (tunai saja) + tombol Bayar.
  Widget _footer(bool dark, Tagihan t) {
    final kembali = t.kembalian(_bayarNum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        border: Border(top: BorderSide(color: dark ? ZK.lineDark : ZK.brand100)),
      ),
      child: Row(
        children: [
          if (_metode.isTunai) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kembali < 0 ? 'Kurang' : 'Kembalian',
                    style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : ZK.slate500)),
                Text(rupiah(kembali.abs()),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: kembali >= 0 ? okTone(dark) : ZK.rose)),
              ],
            ),
            const SizedBox(width: 12),
          ],
          // Simpan sebagai open bill: terlihat langsung, bukan di menu tersembunyi.
          if (widget.onSaveBill != null) ...[
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _loading ? null : _saveBill,
                style: OutlinedButton.styleFrom(
                    foregroundColor: ZK.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: const BorderSide(color: ZK.brand200),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 18),
                    SizedBox(height: 2),
                    Text('Simpan Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : FittedBox(
                        child: Text('Bayar ${rupiah(t.total)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Numpad tablet: 1–9, 000, 0, ⌫ — mengubah field "Uang diterima".
  Widget _numpad(bool dark) {
    void tap(String k) {
      final digits = _bayarNum == 0 ? '' : '$_bayarNum';
      final next = k == '⌫' ? (digits.isEmpty ? '' : digits.substring(0, digits.length - 1)) : digits + k;
      _setBayar(int.tryParse(next) ?? 0);
    }

    return _grid(3, 56, [
      for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '⌫'])
        Material(
          color: dark ? ZK.cardDark : ZK.brand50,
          borderRadius: r12,
          child: InkWell(
            borderRadius: r12,
            onTap: () => tap(k),
            child: Center(
              child: k == '⌫'
                  ? Icon(Icons.backspace_outlined, color: dark ? Colors.white70 : ZK.ink)
                  : Text(k,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
            ),
          ),
        ),
    ]);
  }

  // QRIS statis: tampilkan gambar QR merchant agar pelanggan bisa scan.
  Widget _qrisBox() {
    final q = widget.qris;
    if (q == null || !q.siap) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('QRIS belum diatur di pengaturan merchant.',
            style: TextStyle(fontSize: 12, color: ZK.amber700)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: ZK.brand50, borderRadius: r14),
        child: Column(
          children: [
            CachedNetworkImage(imageUrl: q.imageUrl!,
                height: 190,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    const Text('Gambar QRIS gagal dimuat', style: TextStyle(fontSize: 12, color: ZK.slate500))),
            const SizedBox(height: 6),
            Text(q.merchantName ?? 'QRIS Merchant',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ZK.ink)),
            if (q.nmid != null)
              Text('NMID ${q.nmid}', style: const TextStyle(fontSize: 11, color: ZK.slate500)),
          ],
        ),
      ),
    );
  }

  Widget _metodeTile(JenisBayar j, bool dark) {
    final aktif = j.id == _metode.id;
    return InkWell(
      onTap: () => setState(() => _metode = j),
      borderRadius: r12,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: aktif ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
          borderRadius: r12,
          border: Border.all(color: aktif ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
        ),
        child: Text(j.nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: aktif ? Colors.white : (dark ? Colors.white70 : ZK.muted))),
      ),
    );
  }

  Widget _quickBtn(String label, bool dark, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: r12,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark ? ZK.cardDark : Colors.white,
            borderRadius: r12,
            border: Border.all(color: dark ? ZK.lineDark : ZK.brand200),
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ZK.primary)),
            ),
          ),
        ),
      );
}
