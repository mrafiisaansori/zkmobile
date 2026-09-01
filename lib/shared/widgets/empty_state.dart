import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String title, description;
  final IconData icon;
  const EmptyState(
      {super.key,
      required this.title,
      required this.description,
      this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: dark ? Colors.white38 : ZK.slate400),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : ZK.slate900)),
              const SizedBox(height: 4),
              Text(description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : ZK.slate500)),
            ],
          ),
        ),
    );
  }
}
