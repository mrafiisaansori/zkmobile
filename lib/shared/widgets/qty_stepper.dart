import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus, onPlus;
  const QtyStepper(
      {super.key,
      required this.qty,
      required this.onMinus,
      required this.onPlus});

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
          _btn(Icons.remove, onMinus, dark),
          SizedBox(
            width: 34,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : ZK.slate900)),
          ),
          _btn(Icons.add, onPlus, dark),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, bool dark) => InkWell(
        onTap: onTap,
        borderRadius: r12,
        child: SizedBox(
            height: 32,
            width: 32,
            child: Icon(icon, size: 15, color: dark ? Colors.white60 : ZK.muted)),
      );
}
