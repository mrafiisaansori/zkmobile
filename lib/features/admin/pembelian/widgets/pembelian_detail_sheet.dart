import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../shared/widgets/sheet_common.dart';

// Padanan _PembelianDetailSheet di lib/admin_pembelian_page.dart lama.
class PembelianDetailSheet extends StatelessWidget {
  final Pembelian pembelian;
  const PembelianDetailSheet({super.key, required this.pembelian});

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
              title: pembelian.noNota,
              subtitle: pembelian.namaSupplier ?? 'Tanpa supplier',
              icon: Icons.shopping_cart_outlined,
            ),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pembelian.catatan != null) ...[
                      Text(pembelian.catatan!, style: TextStyle(fontSize: 12, color: muted)),
                      const SizedBox(height: 10),
                    ],
                    for (final d in pembelian.detail)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(d.namaProduk ?? 'Produk ${d.idProduk}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                            ),
                            Text('${d.qty} × ${rupiah(d.hargaBeli)}',
                                style: TextStyle(fontSize: 12, color: muted)),
                            const SizedBox(width: 8),
                            Text(rupiah(d.subtotal),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 13, color: muted)),
                        Text(rupiah(pembelian.total),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: fg)),
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
