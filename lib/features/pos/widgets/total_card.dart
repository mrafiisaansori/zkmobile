import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../models/tagihan.dart';

// Rincian tagihan: subtotal, potongan, pajak, total.
class TotalCard extends StatelessWidget {
  final Tagihan t;
  final TaxSetting? tax;
  const TotalCard({super.key, required this.t, required this.tax});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50, borderRadius: r14),
      child: Column(
        children: [
          _line('Subtotal', rupiah(t.subtotal), dark),
          if (t.diskon > 0) _line('Potongan', '- ${rupiah(t.diskon)}', dark),
          if (t.voucher > 0) _line('Voucher', '- ${rupiah(t.voucher)}', dark),
          if (t.ppn > 0) _line('PPN ${tax?.ppnPersen}%', rupiah(t.ppn), dark),
          if (t.service > 0)
            _line('Service ${tax?.servicePersen}%', rupiah(t.service), dark),
          Divider(height: 16, color: dark ? ZK.lineDark : ZK.brand200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total tagihan',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white70 : ZK.brand700)),
              Text(rupiah(t.total),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : ZK.ink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String l, String v, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
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
