import 'package:flutter/material.dart';
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
import 'sheet_common.dart';
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
    final cart = context.watch<CartCubit>().state;
    final t = _t(cart);
    final total = t.total;
    final tunai = _metode.isTunai;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(
                    title: 'Pembayaran', subtitle: 'Pilih metode & nominal', icon: Icons.payments_outlined),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TotalCard(t: t, tax: widget.tax),
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
                      if (tunai) ...[
                        const SizedBox(height: 16),
                        const FieldLabel('Uang diterima'),
                        TextField(
                          controller: _bayar,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          autofocus: true,
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.slate900),
                          decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _quickBtn('Uang pas', total, dark),
                            for (final q in quick) _quickBtn(rupiah(q), q, dark),
                          ],
                        ),
                        const SizedBox(height: 14),
                        KembalianBox(selisih: t.kembalian(_bayarNum)),
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
                              backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Bayar ${rupiah(total)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                errorBuilder: (_, __, ___) =>
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ZK.primary)),
        ),
      );
}
