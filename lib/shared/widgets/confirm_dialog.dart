import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: r14),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal', style: TextStyle(color: ZK.muted))),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(
              backgroundColor: danger ? ZK.rose : ZK.primary),
          child: const Text('Ya, lanjutkan'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
