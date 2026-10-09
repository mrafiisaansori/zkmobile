import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/sheet_common.dart';

// Padanan _TransaksiDetailSheet di lib/admin_transaksi_page.dart lama.
class TransaksiDetailSheet extends StatelessWidget {
  final Penjualan trx;
  const TransaksiDetailSheet({super.key, required this.trx});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    return Container(
      decoration: sheetBox(dark),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: trx.label,
              subtitle: '${trx.tanggal ?? '-'} ${trx.jam ?? ''}',
              icon: Icons.receipt_long_outlined,
            ),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kasir: ${trx.namaKasir ?? '-'}', style: TextStyle(fontSize: 13, color: muted)),
                    if (trx.jenisBayar != null)
                      Text('Metode: ${trx.jenisBayar}', style: TextStyle(fontSize: 13, color: muted)),
                    const SizedBox(height: 12),
                    for (final d in trx.detail)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${d.namaProduk} x${d.qty}',
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                                  if (d.modifier != null)
                                    Text(d.modifier!, style: TextStyle(fontSize: 11, color: muted)),
                                ],
                              ),
                            ),
                            Text(rupiah(d.subtotal),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                          ],
                        ),
                      ),
                    Divider(color: dark ? ZK.lineDark : ZK.brand100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                        Text(rupiah(trx.total),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
