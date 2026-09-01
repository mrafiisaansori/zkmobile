import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Padanan helper sheet lama di lib/sheets.dart (sheetBox/SheetHeader/
// sheetInput/FieldLabel). Dipakai oleh sheet-sheet fitur closing/ saja —
// pos/ akan punya salinannya sendiri di widgets/sheet_common.dart sesuai
// rencana batch, jadi tidak diduplikasi lintas-fitur lewat import silang.
BoxDecoration sheetBox(bool dark) => BoxDecoration(
      color: dark ? ZK.cardDark : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    );

class SheetHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  final bool showClose;
  const SheetHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.icon = Icons.shopping_cart_outlined,
      this.action,
      this.showClose = true});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(color: ZK.primary, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.slate900)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
              ],
            ),
          ),
          if (action != null) action!,
          if (showClose)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, color: dark ? Colors.white60 : ZK.slate500),
            ),
        ],
      ),
    );
  }
}

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
