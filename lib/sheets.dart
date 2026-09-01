import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'main.dart';
import 'models.dart';
import 'printer.dart';
import 'sound.dart';
import 'theme.dart';
import 'widgets.dart';

BoxDecoration sheetBox(bool dark) => BoxDecoration(
      color: dark ? ZK.cardDark : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    );

class SheetHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  final bool showClose;
  const SheetHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.icon = Icons.shopping_cart_outlined,
      this.action,
      this.showClose = true});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(color: ZK.primary, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.slate900)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
              ],
            ),
          ),
          if (action != null) action!,
          if (showClose)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, color: dark ? Colors.white60 : ZK.slate500),
            ),
        ],
      ),
    );
  }
}

InputDecoration sheetInput(String hint, {String? prefix, bool dark = false}) => InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
      prefixStyle: TextStyle(color: dark ? Colors.white70 : ZK.ink),
      filled: true,
      fillColor: dark ? ZK.bgDark : Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
          borderRadius: r12, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: r12, borderSide: BorderSide(color: ZK.primary, width: 1.6)),
    );

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white70 : const Color(0xFF334155))),
    );
  }
}

// ===== Keranjang (padanan components/pos/Cart.tsx) =====
class CartSheet extends StatefulWidget {
  final bool isPro;
  // Dipakai dua tempat: modal bottom sheet (ponsel) dan panel tetap di
  // sebelah kanan POS (tablet) — embedded=true buang tombol tutup & tinggi
  // tetap ala sheet karena parent-nya (Expanded) yang menentukan ukuran.
  final bool embedded;
  final VoidCallback onCheckout,
      onSaveBill,
      onUpdateBill,
      onCancelBill,
      onSplitBill,
      onPickMember;
  const CartSheet({
    super.key,
    required this.isPro,
    required this.onCheckout,
    required this.onSaveBill,
    required this.onUpdateBill,
    required this.onCancelBill,
    required this.onSplitBill,
    required this.onPickMember,
    this.embedded = false,
  });

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  final _cart = Cart.i;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final body = AnimatedBuilder(
      animation: _cart,
      builder: (context, _) => Column(
          children: [
            SheetHeader(
              title: _cart.billMode ? 'Edit Bill' : 'Keranjang',
              subtitle: _cart.billMode && _cart.bill?.noBill != null
                  ? _cart.bill!.noBill!
                  : '${_cart.items.length} item dipilih',
              showClose: !widget.embedded,
              action: _cart.items.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () {
                        _cart.items.clear();
                        _cart.setDiskon(0);
                      },
                      child: const Text('Kosongkan',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ZK.rose)),
                    ),
            ),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            if (widget.isPro) _memberRow(dark),
            Expanded(
              child: _cart.items.isEmpty
                  ? const EmptyState(
                      title: 'Keranjang masih kosong',
                      description: 'Pilih produk dari grid untuk mulai transaksi.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _cart.items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: dark ? ZK.lineDark : const Color(0xFFF1F5F9)),
                      itemBuilder: (_, i) => _CartRow(
                        item: _cart.items[i],
                        onQty: (q) {
                          final r = _cart.updateQty(_cart.items[i], q);
                          if (!r.ok) toastError(context, r.message!);
                        },
                      ),
                    ),
            ),
            _footer(),
          ],
        ),
    );
    if (widget.embedded) return DecoratedBox(decoration: sheetBox(dark), child: body);
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: sheetBox(dark),
      child: body,
    );
  }

  Widget _memberRow(bool dark) => Padding(
        padding: EdgeInsets.fromLTRB(12, isTablet(context) ? 8 : 12, 12, 0),
        child: InkWell(
          onTap: widget.onPickMember,
          borderRadius: r12,
          child: Container(
            padding: EdgeInsets.all(isTablet(context) ? 8 : 10),
            decoration: BoxDecoration(
              color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50,
              borderRadius: r12,
              border: Border.all(color: dark ? ZK.primary.withValues(alpha: 0.35) : ZK.brand100),
            ),
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: const BoxDecoration(
                      color: ZK.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.person, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_cart.member?.nama ?? 'Tanpa member',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : const Color(0xFF1E293B))),
                      Text(
                          _cart.member == null
                              ? 'Pilih member/customer'
                              : 'Ganti member',
                          style: TextStyle(
                              fontSize: 11, color: dark ? Colors.white60 : ZK.slate500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: dark ? Colors.white38 : ZK.slate400),
              ],
            ),
          ),
        ),
      );

  Widget _footer() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final billMode = _cart.billMode;
    // Footer lebih ringkas di tablet — panel keranjang permanen di sana,
    // jadi ruang yang dihemat di sini balik jadi tinggi tambahan buat daftar
    // item yang bisa discroll (lebih gampang direview sebelum bayar).
    final tablet = isTablet(context);
    final gapSm = tablet ? 6.0 : 10.0;
    final gapMd = tablet ? 8.0 : 12.0;
    final btnH = tablet ? 42.0 : 44.0;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, tablet ? 8 : 12, 16, (tablet ? 8 : 12) + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        border: Border(top: BorderSide(color: dark ? ZK.lineDark : ZK.brand100)),
      ),
      child: Column(
        children: [
          _sumRow('Subtotal', rupiah(_cart.subtotal), dark),
          if (_cart.diskon > 0)
            _sumRow('Potongan', '- ${rupiah(_cart.diskon)}', dark, color: ZK.rose),
          if (_cart.voucher != null)
            _sumRow('Voucher ${_cart.voucher!.kode}',
                '- ${rupiah(_cart.voucher!.diskon)}', dark,
                color: ZK.rose),
          SizedBox(height: gapSm),
          DiskonBox(
              subtotal: _cart.subtotal,
              diskon: _cart.diskon,
              onChanged: _cart.setDiskon),
          SizedBox(height: gapMd),
          Divider(height: 1, color: dark ? ZK.lineDark : const Color(0xFFF1F5F9)),
          SizedBox(height: gapSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white70 : ZK.muted)),
              Text(rupiah(_cart.total),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : ZK.slate900)),
            ],
          ),
          SizedBox(height: gapMd),
          SizedBox(
            height: tablet ? 46 : 48,
            width: double.infinity,
            child: FilledButton(
              onPressed: _cart.items.isEmpty ? null : widget.onCheckout,
              style: FilledButton.styleFrom(
                  backgroundColor: ZK.primary,
                  shape: const RoundedRectangleBorder(borderRadius: r12)),
              child: Text(billMode ? 'Bayar' : 'Bayar Semua',
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          SizedBox(height: gapSm),
          // Split Bill + (Simpan Bill / Simpan+Batalkan) sebaris di tablet
          // supaya cuma makan satu baris tinggi, bukan tumpuk dua-tiga baris.
          if (tablet)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: btnH,
                    child: OutlinedButton.icon(
                      onPressed: _cart.items.isEmpty ? null : widget.onSplitBill,
                      icon: const Icon(Icons.call_split, size: 16),
                      label: const Text('Split Bill', style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.primary,
                          side: const BorderSide(color: ZK.brand200),
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ),
                if (!billMode) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: btnH,
                      child: OutlinedButton.icon(
                        onPressed: _cart.items.isEmpty ? null : widget.onSaveBill,
                        icon: const Icon(Icons.assignment_outlined, size: 16),
                        label: const Text('Simpan Bill', style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: ZK.primary,
                            side: const BorderSide(color: ZK.brand200),
                            shape: const RoundedRectangleBorder(borderRadius: r12)),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            SizedBox(
              height: btnH,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cart.items.isEmpty ? null : widget.onSplitBill,
                icon: const Icon(Icons.call_split, size: 17),
                label: const Text('Split Bill',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: ZK.primary,
                    side: const BorderSide(color: ZK.brand200),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          SizedBox(height: gapSm),
          if (billMode)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: btnH,
                    child: OutlinedButton.icon(
                      onPressed:
                          _cart.items.isEmpty ? null : widget.onUpdateBill,
                      icon: const Icon(Icons.save_outlined, size: 17),
                      label: const Text('Simpan'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.primary,
                          side: const BorderSide(color: ZK.brand200),
                          shape:
                              const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: btnH,
                    child: OutlinedButton.icon(
                      onPressed: widget.onCancelBill,
                      icon: const Icon(Icons.delete_outline, size: 17),
                      label: const Text('Batalkan'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.rose,
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape:
                              const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ),
              ],
            )
          else if (!tablet)
            SizedBox(
              height: btnH,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cart.items.isEmpty ? null : widget.onSaveBill,
                icon: const Icon(Icons.assignment_outlined, size: 17),
                label: const Text('Simpan Bill',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: ZK.primary,
                    side: const BorderSide(color: ZK.brand200),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, bool dark, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 14, color: dark ? Colors.white60 : ZK.slate500)),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color ?? (dark ? Colors.white : ZK.slate900))),
          ],
        ),
      );
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQty;
  const _CartRow({required this.item, required this.onQty});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Tablet: baris dipadatkan (bukan dilebarkan) supaya lebih banyak produk
    // kelihatan sekaligus di panel keranjang tanpa perlu scroll terus.
    final tablet = isTablet(context);
    return Padding(
        padding: EdgeInsets.symmetric(vertical: tablet ? 8 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumb(url: item.produk.foto, size: tablet ? 34 : 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.produk.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: dark ? Colors.white : ZK.slate900)),
                      ),
                      InkWell(
                        onTap: () => onQty(0),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline,
                              size: 18, color: dark ? Colors.white38 : ZK.slate400),
                        ),
                      ),
                    ],
                  ),
                  if (item.modifierText != null)
                    Text(item.modifierText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: ZK.primary)),
                  Text(
                      '${rupiah(item.unit)}${item.produk.satuan != null ? ' / ${item.produk.satuan}' : ''}',
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                  SizedBox(height: tablet ? 4 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      QtyStepper(
                          qty: item.qty,
                          onMinus: () => onQty(item.qty - 1),
                          onPlus: () => onQty(item.qty + 1)),
                      Text(rupiah(item.total),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : ZK.slate900)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

// ===== Pembayaran (padanan components/pos/PaymentModal.tsx) =====
class PaymentSheet extends StatefulWidget {
  final List<JenisBayar> jenisBayar;
  final TaxSetting? tax;
  final Qris? qris;
  final bool isPro;
  final Future<CheckoutResult> Function(JenisBayar, int, String) onConfirm;
  final VoidCallback? onSaveBill;
  const PaymentSheet({
    super.key,
    required this.jenisBayar,
    required this.tax,
    required this.qris,
    required this.isPro,
    required this.onConfirm,
    this.onSaveBill,
  });
  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  static const quick = [50000, 100000, 150000, 200000];
  final _cart = Cart.i;

  late JenisBayar _metode = widget.jenisBayar.first;
  final _bayar = TextEditingController();
  final _ket = TextEditingController();
  final _voucher = TextEditingController();
  bool _loading = false, _cekVoucher = false;

  // Satu sumber kebenaran untuk hitungan uang (lihat test/tagihan_test.dart).
  Tagihan get _t => Tagihan.hitung(
        items: _cart.items,
        diskon: _cart.diskon,
        voucher: _cart.voucher?.diskon ?? 0,
        tax: widget.tax,
        isPro: widget.isPro,
      );
  int get _total => _t.total;
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
    try {
      final v = await Api.validateVoucher(kode, _cart.subtotal);
      _cart.setVoucher(v);
      if (mounted) toastOk(context, 'Voucher ${v.kode} diterapkan');
    } catch (e) {
      _cart.setVoucher(null);
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _cekVoucher = false);
    }
  }

  Future<void> _submit() async {
    // Non-tunai (QRIS/transfer) dianggap bayar pas, sama seperti web.
    final bayar = _metode.isTunai ? _bayarNum : _total;
    if (bayar < _total) {
      toastError(context, 'Nominal bayar kurang dari total');
      return;
    }
    setState(() => _loading = true);
    try {
      final ket = _ket.text.trim().isEmpty && _metode.isQris
          ? 'Pembayaran QRIS Manual'
          : _ket.text.trim();
      final itemsSnapshot = List<CartItem>.from(_cart.items);
      final res = await widget.onConfirm(_metode, bayar, ket);
      if (!mounted) return;
      Navigator.pop(context);
      playSuccessSound();
      toastOk(
          context,
          res.offline
              ? 'Koneksi terputus — transaksi disimpan offline & otomatis dikirim saat online lagi.'
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
    final tunai = _metode.isTunai;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(
                    title: 'Pembayaran',
                    subtitle: 'Pilih metode & nominal',
                    icon: Icons.payments_outlined),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TotalCard(t: _t, tax: widget.tax),
                      const SizedBox(height: 16),
                      const FieldLabel('Metode pembayaran'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final j in widget.jenisBayar) _metodeChip(j, dark),
                        ],
                      ),
                      if (_metode.isQris) _qrisBox(),
                      const SizedBox(height: 16),
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
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: r12)),
                              child: _cekVoucher
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: ZK.primary))
                                  : const Text('Pakai'),
                            ),
                          ),
                        ],
                      ),
                      if (tunai) ...[
                        const SizedBox(height: 16),
                        const FieldLabel('Uang diterima'),
                        TextField(
                          controller: _bayar,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          autofocus: true,
                          inputFormatters: [
                            RupiahInputFormatter()
                          ],
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : ZK.slate900),
                          decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _quickBtn('Uang pas', _total, dark),
                            for (final q in quick) _quickBtn(rupiah(q), q, dark),
                          ],
                        ),
                        const SizedBox(height: 14),
                        KembalianBox(selisih: _t.kembalian(_bayarNum)),
                      ],
                      const SizedBox(height: 14),
                      const FieldLabel('Keterangan (opsional)'),
                      TextField(
                          controller: _ket,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. pesanan take away', dark: dark)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: r12)),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('Bayar ${rupiah(_total)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                        ),
                      ),
                      if (widget.onSaveBill != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    widget.onSaveBill!();
                                  },
                            icon: const Icon(Icons.assignment_outlined, size: 17),
                            label: const Text('Simpan sebagai Open Bill',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: ZK.primary,
                                side: const BorderSide(color: ZK.brand200),
                                shape: const RoundedRectangleBorder(borderRadius: r12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            Image.network(q.imageUrl!,
                height: 190,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('Gambar QRIS gagal dimuat',
                    style: TextStyle(fontSize: 12, color: ZK.slate500))),
            const SizedBox(height: 6),
            Text(q.merchantName ?? 'QRIS Merchant',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: ZK.ink)),
            if (q.nmid != null)
              Text('NMID ${q.nmid}',
                  style: const TextStyle(fontSize: 11, color: ZK.slate500)),
          ],
        ),
      ),
    );
  }

  Widget _metodeChip(JenisBayar j, bool dark) {
    final aktif = j.id == _metode.id;
    return InkWell(
      onTap: () => setState(() => _metode = j),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: aktif ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
        ),
        child: Text(j.nama,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: aktif ? Colors.white : (dark ? Colors.white70 : ZK.muted))),
      ),
    );
  }

  Widget _quickBtn(String label, int nominal, bool dark) => InkWell(
        onTap: () => setState(() => _bayar.text = rupiahPlain(nominal)),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: dark ? ZK.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: dark ? ZK.lineDark : ZK.brand200),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: ZK.primary)),
        ),
      );
}

// ===== Varian / modifier (padanan modal modifier di pos/page.tsx) =====
class ModifierSheet extends StatefulWidget {
  final Produk produk;
  final List<ModifierGroup> groups;
  const ModifierSheet({super.key, required this.produk, required this.groups});
  @override
  State<ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends State<ModifierSheet> {
  final Map<int, List<int>> _sel = {};

  @override
  void initState() {
    super.initState();
    for (final g in widget.groups) {
      _sel[g.id] = [];
    }
  }

  void _toggle(ModifierGroup g, int optionId) {
    setState(() {
      final cur = _sel[g.id] ?? [];
      if (g.single) {
        _sel[g.id] = [optionId];
      } else {
        _sel[g.id] =
            cur.contains(optionId) ? (cur..remove(optionId)) : (cur..add(optionId));
      }
    });
  }

  List<ModifierOption> get _chosen => [
        for (final g in widget.groups)
          for (final id in _sel[g.id] ?? [])
            ...g.options.where((o) => o.id == id),
      ];

  void _confirm() {
    for (final g in widget.groups) {
      if (g.wajib && (_sel[g.id] ?? []).isEmpty) {
        toastError(context, 'Pilih ${g.nama} dulu');
        return;
      }
    }
    Navigator.pop(context, _chosen);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final extra = _chosen.fold<int>(0, (s, o) => s + o.harga);
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: sheetBox(dark),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
                title: widget.produk.nama,
                subtitle: 'Pilih varian',
                icon: Icons.tune),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                shrinkWrap: true,
                children: [
                  for (final g in widget.groups) _group(g, dark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary,
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: Text(
                      'Tambah · ${rupiah(widget.produk.hargaJual + extra)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(ModifierGroup g, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(g.nama,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.ink)),
                const SizedBox(width: 6),
                if (g.wajib)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: ZK.rose50, borderRadius: BorderRadius.circular(999)),
                    child: const Text('Wajib',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ZK.rose)),
                  ),
                const Spacer(),
                Text(g.single ? 'Pilih satu' : 'Boleh banyak',
                    style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : ZK.slate500)),
              ],
            ),
            const SizedBox(height: 8),
            for (final o in g.options)
              InkWell(
                onTap: () => _toggle(g, o.id),
                borderRadius: r12,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: (_sel[g.id] ?? []).contains(o.id)
                        ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50)
                        : (dark ? ZK.cardDark : Colors.white),
                    borderRadius: r12,
                    border: Border.all(
                        color: (_sel[g.id] ?? []).contains(o.id)
                            ? ZK.primary
                            : (dark ? ZK.lineDark : ZK.line)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (_sel[g.id] ?? []).contains(o.id)
                            ? (g.single
                                ? Icons.radio_button_checked
                                : Icons.check_box)
                            : (g.single
                                ? Icons.radio_button_unchecked
                                : Icons.check_box_outline_blank),
                        size: 19,
                        color: (_sel[g.id] ?? []).contains(o.id)
                            ? ZK.primary
                            : (dark ? Colors.white38 : ZK.slate400),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(o.nama,
                            style: TextStyle(
                                fontSize: 14,
                                color: dark ? Colors.white : const Color(0xFF1E293B))),
                      ),
                      if (o.harga != 0)
                        Text('+ ${rupiah(o.harga)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ZK.primary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

// ===== Pilih member (padanan MemberPickerModal.tsx) =====
class MemberPickerSheet extends StatefulWidget {
  final Member? selected;
  const MemberPickerSheet({super.key, this.selected});
  @override
  State<MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<MemberPickerSheet> {
  final _q = TextEditingController();
  List<Member> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.member(search: _q.text);
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: sheetBox(dark),
          child: Column(
            children: [
              const SheetHeader(
                  title: 'Pilih Member',
                  subtitle: 'Member/customer untuk transaksi ini',
                  icon: Icons.people_outline),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _q,
                  onSubmitted: (_) => _load(),
                  style: TextStyle(color: dark ? Colors.white : ZK.ink),
                  decoration: sheetInput('Cari nama / no HP...', dark: dark).copyWith(
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: ZK.slate400),
                    suffixIcon: IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.arrow_forward,
                            size: 18, color: ZK.primary)),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: ZK.primary))
                    : _data.isEmpty
                        ? const EmptyState(
                            title: 'Member tidak ditemukan',
                            description: 'Tambah member lewat aplikasi web.')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _data.length,
                            itemBuilder: (_, i) {
                              final m = _data[i];
                              final aktif = widget.selected?.id == m.id;
                              return ListTile(
                                onTap: () => Navigator.pop(context, m),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: r12),
                                leading: CircleAvatar(
                                  backgroundColor: ZK.brand50,
                                  child: Text(
                                      m.nama.isEmpty
                                          ? '?'
                                          : m.nama[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: ZK.primary,
                                          fontWeight: FontWeight.w800)),
                                ),
                                title: Text(m.nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                subtitle: Text(
                                    '${m.noHp}${m.kode != null ? ' · ${m.kode}' : ''}',
                                    style: const TextStyle(fontSize: 12)),
                                trailing: aktif
                                    ? const Icon(Icons.check_circle,
                                        color: ZK.primary)
                                    : null,
                              );
                            },
                          ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 12 + MediaQuery.of(context).padding.bottom),
                child: SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: OutlinedButton(
                    // id -1 = sinyal "tanpa member" ke pemanggil.
                    onPressed: () => Navigator.pop(
                        context, Member.fromJson({'ID': -1, 'NAMA': ''})),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: dark ? Colors.white70 : ZK.slate500,
                        side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                    child: const Text('Tanpa member'),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ===== Form open bill (simpan / ubah data bill) =====
class BillFormSheet extends StatefulWidget {
  final String customer, table, note;
  const BillFormSheet(
      {super.key, this.customer = '', this.table = '', this.note = ''});
  @override
  State<BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<BillFormSheet> {
  late final _c = TextEditingController(text: widget.customer);
  late final _t = TextEditingController(text: widget.table);
  late final _n = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _c.dispose();
    _t.dispose();
    _n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: sheetBox(dark),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeader(
                    title: widget.customer.isEmpty
                        ? 'Simpan sebagai Open Bill'
                        : 'Ubah data bill',
                    subtitle: '${Cart.i.count} item akan disimpan',
                    icon: Icons.assignment_outlined),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Nama pelanggan / nama bill'),
                      TextField(
                          controller: _c,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. Budi / Take away', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Nomor meja (opsional)'),
                      TextField(
                          controller: _t,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. 04', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Catatan (opsional)'),
                      TextField(
                          controller: _n,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration:
                              sheetInput('mis. es sedikit, tanpa gula', dark: dark)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: dark ? ZK.bgDark : const Color(0xFFF8FAFC),
                            borderRadius: r12),
                        child: Text('Stok belum dipotong sampai bill dibayar.',
                            style: TextStyle(
                                fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, {
                            'customer': _c.text.trim(),
                            'table': _t.text.trim(),
                            'note': _n.text.trim(),
                          }),
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: r12)),
                          child: const Text('Simpan Bill',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

// ===== Split bill (padanan components/pos/SplitBillModal.tsx) =====
// Setiap qty dipecah jadi satu "chip" yang bisa dipindah antar orang.
class _Unit {
  final String id, lineId, label;
  final int? detailId;
  final int unitPrice;
  final String? modifierText;
  final CartItem source;
  int person;
  _Unit(this.id, this.lineId, this.label, this.unitPrice, this.person,
      this.source, this.detailId, this.modifierText);
}

class SplitPayload {
  final List<CartItem> items; // baris untuk checkout biasa
  final Map<String, int> perLine; // lineId keranjang -> qty dibayar
  final Map<int, int> perDetail; // id_open_bill_detail -> qty (mode bill)
  final JenisBayar metode;
  final int bayar;
  final String payerName, keterangan;
  SplitPayload(this.items, this.perLine, this.perDetail, this.metode,
      this.bayar, this.payerName, this.keterangan);
}

class SplitBillSheet extends StatefulWidget {
  final List<JenisBayar> jenisBayar;
  final TaxSetting? tax;
  final Qris? qris;
  final bool isPro;
  final Future<CheckoutResult> Function(SplitPayload) onPay;
  const SplitBillSheet({
    super.key,
    required this.jenisBayar,
    required this.tax,
    required this.qris,
    required this.isPro,
    required this.onPay,
  });
  @override
  State<SplitBillSheet> createState() => _SplitBillSheetState();
}

class _SplitBillSheetState extends State<SplitBillSheet> {
  final _cart = Cart.i;
  int _orang = 2;
  List<_Unit> _units = [];
  int? _aktif;
  late JenisBayar _metode = widget.jenisBayar.first;
  final _bayar = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void dispose() {
    _bayar.dispose();
    super.dispose();
  }

  // Sebar unit bergiliran ke tiap orang (round-robin), sama seperti buildUnits di web.
  void _build() {
    final list = <_Unit>[];
    for (final it in _cart.items) {
      for (var n = 1; n <= it.qty; n++) {
        list.add(_Unit(
          '${it.lineId}-$n',
          it.lineId,
          it.qty > 1 ? '${it.produk.nama} #$n' : it.produk.nama,
          it.unit,
          (list.length % _orang) + 1,
          it,
          it.openBillDetailId,
          it.modifierText,
        ));
      }
    }
    setState(() {
      _units = list;
      _aktif = null;
    });
  }

  void _setOrang(int n) {
    if (n < 1 || n > 12) return;
    setState(() {
      _orang = n;
      for (var i = 0; i < _units.length; i++) {
        if (_units[i].person > n) _units[i].person = (i % n) + 1;
      }
      if (_aktif != null && _aktif! > n) _aktif = null;
    });
  }

  // Tap chip = pindah ke orang berikutnya (mekanik yang sama dengan moveChip di web).
  void _move(_Unit u) => setState(
      () => u.person = u.person >= _orang ? 1 : u.person + 1);

  List<_Unit> _milik(int person) =>
      _units.where((u) => u.person == person).toList();

  Tagihan _tagihan(List<_Unit> units) {
    final items = <CartItem>[];
    final grouped = <String, int>{};
    for (final u in units) {
      grouped[u.lineId] = (grouped[u.lineId] ?? 0) + 1;
    }
    for (final e in grouped.entries) {
      final src = _units.firstWhere((u) => u.lineId == e.key).source;
      items.add(CartItem(src.produk, e.value,
          modifiers: src.modifiers, openBillDetailId: src.openBillDetailId));
    }
    return Tagihan.hitung(items: items, tax: widget.tax, isPro: widget.isPro);
  }

  Future<void> _bayarOrang() async {
    final person = _aktif;
    if (person == null) return;
    final units = _milik(person);
    if (units.isEmpty) {
      toastError(context, 'Orang $person belum kebagian item');
      return;
    }
    final t = _tagihan(units);
    final bayar = _metode.isTunai ? (parseRupiah(_bayar.text)) : t.total;
    if (bayar < t.total) {
      toastError(context, 'Nominal bayar kurang dari total');
      return;
    }

    // Kelompokkan unit -> baris keranjang & detail bill.
    final perLine = <String, int>{};
    final perDetail = <int, int>{};
    for (final u in units) {
      perLine[u.lineId] = (perLine[u.lineId] ?? 0) + 1;
      if (u.detailId != null) {
        perDetail[u.detailId!] = (perDetail[u.detailId!] ?? 0) + 1;
      }
    }
    // Baris untuk checkout; pemanggil memakai perLine untuk mengurangi keranjang.
    final items = [
      for (final e in perLine.entries)
        () {
          final src = _units.firstWhere((u) => u.lineId == e.key).source;
          return CartItem(src.produk, e.value,
              modifiers: src.modifiers,
              openBillDetailId: src.openBillDetailId,
              stok: src.stok);
        }()
    ];

    setState(() => _loading = true);
    try {
      final res = await widget.onPay(SplitPayload(
        items,
        perLine,
        perDetail,
        _metode,
        bayar,
        'Orang $person',
        'Split Bill - Orang $person',
      ));
      if (!mounted) return;
      _bayar.clear();
      // Buang unit yang sudah dibayar; sisanya masih bisa dibayar orang lain.
      setState(() {
        _units.removeWhere((u) => u.person == person);
        _aktif = null;
      });
      if (_units.isEmpty && mounted) Navigator.pop(context);
      if (!mounted) return;
      playSuccessSound();
      toastOk(context, 'Pembayaran $person berhasil diselesaikan');
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SuccessSheet(
            result: res, metode: _metode.nama, items: items, judul: 'Split bill dibayar'),
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
    final t = _aktif == null ? _tagihan(_units) : _tagihan(_milik(_aktif!));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: sheetBox(dark),
        child: Column(
          children: [
            const SheetHeader(
                title: 'Split Bill',
                subtitle: 'Bagi item lalu bayar per orang',
                icon: Icons.call_split),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Jumlah orang',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white70 : const Color(0xFF334155))),
                  const Spacer(),
                  QtyStepper(
                      qty: _orang,
                      onMinus: () => _setOrang(_orang - 1),
                      onPlus: () => _setOrang(_orang + 1)),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: _build, child: const Text('Bagi rata')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  Text('Ketuk item untuk memindahkannya ke orang lain.',
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                  const SizedBox(height: 10),
                  for (var p = 1; p <= _orang; p++) _kartuOrang(p, dark),
                ],
              ),
            ),
            _footer(t, dark),
          ],
        ),
      ),
    );
  }

  Widget _kartuOrang(int person, bool dark) {
    final units = _milik(person);
    final t = _tagihan(units);
    final aktif = _aktif == person;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: aktif
            ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50)
            : (dark ? ZK.cardDark : Colors.white),
        borderRadius: r14,
        border: Border.all(color: aktif ? ZK.primary : (dark ? ZK.lineDark : ZK.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 26,
                width: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: ZK.primary, shape: BoxShape.circle),
                child: Text('$person',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text('Orang $person',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : ZK.ink)),
              const Spacer(),
              Text(rupiah(t.total),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : ZK.slate900)),
            ],
          ),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Belum ada item',
                  style: TextStyle(fontSize: 12, color: dark ? Colors.white38 : ZK.slate400)),
            )
          else ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final u in units)
                  InkWell(
                    onTap: () => _move(u),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: dark ? ZK.bgDark : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: dark ? ZK.lineDark : ZK.brand200),
                      ),
                      child: Text('${u.label} · ${rupiah(u.unitPrice)}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: dark ? Colors.white : const Color(0xFF1E293B))),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: units.isEmpty
                  ? null
                  : () => setState(() => _aktif = aktif ? null : person),
              style: OutlinedButton.styleFrom(
                  foregroundColor: aktif ? ZK.primary : (dark ? Colors.white70 : ZK.muted),
                  side: BorderSide(color: aktif ? ZK.primary : (dark ? ZK.lineDark : ZK.line)),
                  shape: const RoundedRectangleBorder(borderRadius: r12)),
              child: Text(aktif ? 'Dipilih untuk dibayar' : 'Bayar orang ini',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(Tagihan t, bool dark) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          border: Border(top: BorderSide(color: dark ? ZK.lineDark : ZK.brand100)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_aktif == null ? 'Total semua' : 'Tagihan orang $_aktif',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : ZK.muted)),
                Text(rupiah(t.total),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: dark ? Colors.white : ZK.ink)),
              ],
            ),
            if (_aktif != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final j in widget.jenisBayar)
                    InkWell(
                      onTap: () => setState(() => _metode = j),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _metode.id == j.id
                              ? ZK.primary
                              : (dark ? ZK.bgDark : Colors.white),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: _metode.id == j.id
                                  ? ZK.primary
                                  : (dark ? ZK.lineDark : ZK.brand200)),
                        ),
                        child: Text(j.nama,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _metode.id == j.id
                                    ? Colors.white
                                    : (dark ? Colors.white70 : ZK.muted))),
                      ),
                    ),
                ],
              ),
              if (_metode.isTunai) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _bayar,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  inputFormatters: [RupiahInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: dark ? Colors.white : ZK.ink),
                  decoration: sheetInput('Uang diterima', prefix: 'Rp  ', dark: dark),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _bayarOrang,
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary,
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Bayar ${rupiah(t.total)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ],
        ),
      );
}

// ===== Buka sesi kasir =====
class BukaSesiSheet extends StatefulWidget {
  const BukaSesiSheet({super.key});
  @override
  State<BukaSesiSheet> createState() => _BukaSesiSheetState();
}

class _BukaSesiSheetState extends State<BukaSesiSheet> {
  final _modal = TextEditingController(text: '0');
  final _catatan = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _modal.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await Api.openShift(parseRupiah(_modal.text),
          catatan: _catatan.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
      toastOk(context, 'Sesi kasir dibuka');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: sheetBox(dark),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(
                    title: 'Buka Sesi Kasir',
                    subtitle: 'Transaksi baru bisa dimulai setelah sesi dibuka',
                    icon: Icons.lock_open),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Modal awal laci'),
                      TextField(
                        controller: _modal,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        inputFormatters: [RupiahInputFormatter()],
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                      ),
                      const SizedBox(height: 14),
                      const FieldLabel('Catatan (opsional)'),
                      TextField(
                          controller: _catatan,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. shift pagi', dark: dark)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: r12)),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Buka Sesi',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

// ===== Struk sukses =====
class SuccessSheet extends StatelessWidget {
  final CheckoutResult result;
  final String metode, judul;
  final List<CartItem> items;
  const SuccessSheet(
      {super.key,
      required this.result,
      required this.metode,
      this.items = const [],
      this.judul = 'Transaksi berhasil'});

  Future<void> _kirimWA(BuildContext context) async {
    final nomor = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WaNumberSheet(),
    );
    if (nomor == null || nomor.isEmpty || !context.mounted) return;
    try {
      final ok = await Api.kirimWA(result.id, nomor);
      if (!context.mounted) return;
      ok ? toastOk(context, 'Struk terkirim ke WhatsApp')
         : toastError(context, 'Gagal mengirim struk');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  void _cetak(BuildContext context) {
    final receipt = PrintableReceipt(
      noNota: result.noNota,
      tanggal: DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' '),
      items: [
        for (final it in items)
          ReceiptLine(it.produk.nama, it.qty, it.unit, it.total, it.modifierText)
      ],
      total: result.total,
      bayar: result.bayar,
      kembalian: result.kembalian,
      metode: metode,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrinterPickerSheet(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle,
                      size: 40, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 14),
                Text(judul,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.ink)),
                const SizedBox(height: 4),
                Text(result.noNota,
                    style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : ZK.slate500)),
                if (result.offline) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: ZK.amber50, borderRadius: BorderRadius.circular(999)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 13, color: ZK.amber700),
                        SizedBox(width: 5),
                        Text('Tersimpan offline — akan disinkron otomatis',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: ZK.amber700)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50,
                      borderRadius: r14),
                  child: Column(
                    children: [
                      _row('Metode', metode, dark),
                      _row('Total', rupiah(result.total), dark),
                      _row('Bayar', rupiah(result.bayar), dark),
                      if (result.remainingTotal > 0)
                        _row('Sisa bill', rupiah(result.remainingTotal), dark),
                      Divider(height: 16, color: dark ? ZK.lineDark : ZK.brand200),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kembalian',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? Colors.white70 : ZK.brand700)),
                          Text(rupiah(result.kembalian),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: dark ? Colors.white : ZK.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Cetak 100% lokal ke printer Bluetooth — tidak butuh ID
                    // server, jadi tetap tersedia walau transaksinya offline
                    // (struk sementara, no nota resmi menyusul saat sinkron).
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => _cetak(context),
                          icon: const Icon(Icons.print_outlined, size: 17),
                          label: const Text('Cetak Struk'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: ZK.primary,
                              side: const BorderSide(color: ZK.brand200),
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                        ),
                      ),
                    ),
                    if (!result.offline) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: () => _kirimWA(context),
                            icon: const Icon(Icons.message_outlined, size: 17),
                            label: const Text('Kirim WA'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: ZK.primary,
                                side: const BorderSide(color: ZK.brand200),
                                shape: const RoundedRectangleBorder(borderRadius: r12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary,
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                    child: const Text('Selesai',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _row(String l, String v, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : ZK.muted)),
            Text(v,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : ZK.slate900)),
          ],
        ),
      );
}

// ===== Kirim struk via WhatsApp — dipakai di POS & Riwayat detail =====
class WaNumberSheet extends StatefulWidget {
  const WaNumberSheet({super.key});
  @override
  State<WaNumberSheet> createState() => _WaNumberSheetState();
}

class _WaNumberSheetState extends State<WaNumberSheet> {
  final _nomor = TextEditingController();

  @override
  void dispose() {
    _nomor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: sheetBox(dark),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Kirim Struk via WhatsApp',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : ZK.ink)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nomor,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: TextStyle(color: dark ? Colors.white : ZK.ink),
                    decoration: sheetInput('081234567890', dark: dark),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        final n = _nomor.text.replaceAll(RegExp(r'\D'), '');
                        if (n.length < 9) {
                          toastError(context, 'Nomor WhatsApp belum valid');
                          return;
                        }
                        Navigator.pop(context, n);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: ZK.primary,
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                      child: const Text('Kirim',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

// ===== Pilih printer Bluetooth untuk cetak struk =====
class PrinterPickerSheet extends StatefulWidget {
  final PrintableReceipt receipt;
  const PrinterPickerSheet({super.key, required this.receipt});
  @override
  State<PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends State<PrinterPickerSheet> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true, _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await PrinterService.pairedDevices();
    if (mounted) setState(() { _devices = d; _loading = false; });
  }

  Future<void> _print(BluetoothDevice device) async {
    setState(() => _printing = true);
    try {
      final id = await tokoIdentitas();
      await PrinterService.printReceipt(
        device,
        noNota: widget.receipt.noNota,
        tanggal: widget.receipt.tanggal,
        items: widget.receipt.items,
        total: widget.receipt.total,
        bayar: widget.receipt.bayar,
        kembalian: widget.receipt.kembalian,
        namaToko: id['nama'],
        alamatToko: id['alamat'],
        kasir: widget.receipt.kasir,
        metode: widget.receipt.metode,
        status: widget.receipt.status,
        showBranding: !Session.isPro,
      );
      if (!mounted) return;
      Navigator.pop(context);
      toastOk(context, 'Struk terkirim ke printer');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(
                  title: 'Cetak Struk',
                  subtitle: 'Pilih printer Bluetooth yang sudah dipasangkan',
                  icon: Icons.print_outlined),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: ZK.primary)),
                )
              else if (_devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyState(
                      icon: Icons.bluetooth_disabled,
                      title: 'Belum ada printer terpasang',
                      description:
                          'Pasangkan printer Bluetooth lewat pengaturan HP dulu, lalu coba lagi.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _devices.length,
                    itemBuilder: (_, i) {
                      final d = _devices[i];
                      return ListTile(
                        enabled: !_printing,
                        leading: const Icon(Icons.print_outlined, color: ZK.primary),
                        title: Text(d.name ?? 'Printer',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(d.address ?? ''),
                        onTap: () => _print(d),
                      );
                    },
                  ),
                ),
              if (_printing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Mencetak...',
                      style: TextStyle(color: dark ? Colors.white60 : ZK.slate500)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
    );
  }
}
