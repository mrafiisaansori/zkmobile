import 'package:flutter/material.dart';
import '../../../core/printer/printer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/pos_repository.dart';
import '../models/cart_item.dart';
import 'printer_picker_sheet.dart';
import '../../../shared/widgets/sheet_common.dart';
import 'wa_number_sheet.dart';

// ===== Struk sukses =====
class SuccessSheet extends StatelessWidget {
  final CheckoutResult result;
  final String metode, judul;
  final List<CartItem> items;
  // Nama member transaksi (dicatat sebelum keranjang dikosongkan checkout).
  final String? member;
  const SuccessSheet(
      {super.key,
      required this.result,
      required this.metode,
      this.items = const [],
      this.member,
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
      final ok = await PosRepository().kirimWA(result.id, nomor);
      if (!context.mounted) return;
      ok ? toastOk(context, 'Struk terkirim ke WhatsApp') : toastError(context, 'Gagal mengirim struk');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  void _cetak(BuildContext context) {
    final receipt = PrintableReceipt(
      noNota: result.noNota,
      tanggal: DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' '),
      items: [
        for (final it in items) ReceiptLine(it.produk.nama, it.qty, it.unit, it.total, it.modifierText)
      ],
      total: result.total,
      bayar: result.bayar,
      kembalian: result.kembalian,
      member: member,
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
                decoration: BoxDecoration(color: softBg(ZK.success, ZK.successBg, dark), shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 40, color: okTone(dark)),
              ),
              const SizedBox(height: 14),
              Text(judul,
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
              const SizedBox(height: 4),
              Text(result.noNota, style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : ZK.slate500)),
              if (result.offline) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: softBg(ZK.amber700, ZK.amber50, dark), borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 13, color: ZK.amber700),
                      SizedBox(width: 5),
                      Text('Tersimpan offline: akan disinkron otomatis',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ZK.amber700)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50, borderRadius: r14),
                child: Column(
                  children: [
                    _row('Metode', metode, dark),
                    _row('Total', rupiah(result.total), dark),
                    _row('Bayar', rupiah(result.bayar), dark),
                    if (result.remainingTotal > 0) _row('Sisa bill', rupiah(result.remainingTotal), dark),
                    Divider(height: 16, color: dark ? ZK.lineDark : ZK.brand200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kembalian',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: dark ? Colors.white70 : ZK.brand700)),
                        Text(rupiah(result.kembalian),
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : ZK.ink)),
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
                      backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: const Text('Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                    fontSize: 13, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.slate900)),
          ],
        ),
      );
}
