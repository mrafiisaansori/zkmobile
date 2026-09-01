import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Banner sesi kasir belum dibuka — sekaligus jalan pintas membukanya.
class ShiftBanner extends StatelessWidget {
  final VoidCallback onBuka;
  const ShiftBanner({super.key, required this.onBuka});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onBuka,
        borderRadius: r12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: ZK.amber50,
            borderRadius: r12,
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: ZK.amber700),
              SizedBox(width: 8),
              Expanded(
                child: Text('Sesi kasir belum dibuka — ketuk untuk membuka.',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ZK.amber700)),
              ),
              Icon(Icons.chevron_right, size: 18, color: ZK.amber700),
            ],
          ),
        ),
      );
}
