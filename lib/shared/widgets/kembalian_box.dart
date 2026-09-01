import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/formatters.dart';

class KembalianBox extends StatelessWidget {
  final int selisih;
  const KembalianBox({super.key, required this.selisih});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final kurang = selisih < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: kurang
              ? (dark ? ZK.rose.withValues(alpha: 0.16) : ZK.rose50)
              : (dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50),
          borderRadius: r12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(kurang ? 'Kurang' : 'Kembalian',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kurang ? ZK.rose : (dark ? Colors.white70 : ZK.brand700))),
          Text(rupiah(selisih.abs()),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kurang ? ZK.rose : (dark ? Colors.white : ZK.brand700))),
        ],
      ),
    );
  }
}
