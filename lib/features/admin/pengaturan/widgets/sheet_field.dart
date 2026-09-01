import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// FieldLabel/sheetInput padanan lib/sheets.dart lama — versi lengkapnya
// (dipakai form-sheet POS) belum dipindahkan di batch ini, jadi 3 tab
// pengaturan pakai salinan minimal ini alih-alih menunggu/membuat file di
// luar folder features/admin/pengaturan/ (di luar cakupan batch ini).
InputDecoration sheetInput(String hint, {String? prefix, bool dark = false}) => InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
      prefixStyle: TextStyle(color: dark ? Colors.white70 : ZK.ink),
      filled: true,
      fillColor: dark ? ZK.bgDark : Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
          borderRadius: r12, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: r12, borderSide: BorderSide(color: ZK.primary, width: 1.6)),
    );

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white70 : const Color(0xFF334155))),
    );
  }
}

Widget settingsCard(bool dark, {required Widget child}) => Container(
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r14,
        border: Border.all(color: dark ? ZK.lineDark : ZK.line),
      ),
      child: child,
    );
