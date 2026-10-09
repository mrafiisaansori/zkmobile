import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus, onPlus;
  // Saat qty == 1 tombol minus tampil sebagai hapus (target 40×40).
  final bool deleteAtOne;
  const QtyStepper(
      {super.key,
      required this.qty,
      required this.onMinus,
      required this.onPlus,
      this.deleteAtOne = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
          borderRadius: r12,
          border: Border.all(color: dark ? ZK.lineDark : const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (deleteAtOne && qty == 1)
            _btn(Icons.delete_outline, onMinus, dark, color: ZK.rose, size: 40)
          else
            _btn(Icons.remove, onMinus, dark, size: deleteAtOne ? 40 : 32),
          SizedBox(
            width: 34,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : ZK.slate900)),
          ),
          _btn(Icons.add, onPlus, dark, size: deleteAtOne ? 40 : 32),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, bool dark, {Color? color, double size = 32}) => InkWell(
        onTap: onTap,
        borderRadius: r12,
        child: SizedBox(
            height: size,
            width: size,
            child: Icon(icon, size: color == null ? 15 : 18, color: color ?? (dark ? Colors.white60 : ZK.muted))),
      );
}
