import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../shared/widgets/sheet_common.dart';

// Padanan _ReturDetailSheet di lib/admin_retur_page.dart lama.
class ReturDetailSheet extends StatelessWidget {
  final Retur retur;
  const ReturDetailSheet({super.key, required this.retur});

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
              title: retur.noNota,
              subtitle: retur.namaSupplier ?? 'Tanpa supplier',
              icon: Icons.assignment_return_outlined,
            ),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (retur.noNotaPembelian != null) ...[
                      Text('Pembelian asal: ${retur.noNotaPembelian}',
                          style: TextStyle(fontSize: 12, color: muted)),
                      const SizedBox(height: 6),
                    ],
                    if (retur.catatan != null) ...[
                      Text(retur.catatan!, style: TextStyle(fontSize: 12, color: muted)),
                      const SizedBox(height: 10),
                    ],
                    for (final d in retur.detail)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(d.namaProduk ?? 'Produk ${d.idProduk}',
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                                ),
                                Text('${d.qty} unit', style: TextStyle(fontSize: 12, color: muted)),
                              ],
                            ),
                            if (d.kondisi != null || d.alasan != null)
                              Text([if (d.kondisi != null) d.kondisi!, if (d.alasan != null) d.alasan!]
                                  .join(' · '),
                                  style: TextStyle(fontSize: 11, color: muted)),
                          ],
                        ),
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
