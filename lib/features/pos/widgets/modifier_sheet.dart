import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'sheet_common.dart';

// ===== Varian / modifier (padanan modal modifier di pos/page.tsx) =====
class ModifierSheet extends StatefulWidget {
  final Produk produk;
  final List<ModifierGroup> groups;
  const ModifierSheet({super.key, required this.produk, required this.groups});
  @override
  State<ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends State<ModifierSheet> {
  final Map<int, List<int>> _sel = {};

  @override
  void initState() {
    super.initState();
    for (final g in widget.groups) {
      _sel[g.id] = [];
    }
  }

  void _toggle(ModifierGroup g, int optionId) {
    setState(() {
      final cur = _sel[g.id] ?? [];
      if (g.single) {
        _sel[g.id] = [optionId];
      } else {
        _sel[g.id] = cur.contains(optionId) ? (cur..remove(optionId)) : (cur..add(optionId));
      }
    });
  }

  List<ModifierOption> get _chosen => [
        for (final g in widget.groups)
          for (final id in _sel[g.id] ?? [])
            ...g.options.where((o) => o.id == id),
      ];

  void _confirm() {
    for (final g in widget.groups) {
      if (g.wajib && (_sel[g.id] ?? []).isEmpty) {
        toastError(context, 'Pilih ${g.nama} dulu');
        return;
      }
    }
    Navigator.pop(context, _chosen);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final extra = _chosen.fold<int>(0, (s, o) => s + o.harga);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: sheetBox(dark),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: widget.produk.nama, subtitle: 'Pilih varian', icon: Icons.tune),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                shrinkWrap: true,
                children: [
                  for (final g in widget.groups) _group(g, dark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: Text('Tambah · ${rupiah(widget.produk.hargaJual + extra)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(ModifierGroup g, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(g.nama,
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
                const SizedBox(width: 6),
                if (g.wajib)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: ZK.rose50, borderRadius: BorderRadius.circular(999)),
                    child: const Text('Wajib',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ZK.rose)),
                  ),
                const Spacer(),
                Text(g.single ? 'Pilih satu' : 'Boleh banyak',
                    style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : ZK.slate500)),
              ],
            ),
            const SizedBox(height: 8),
            for (final o in g.options)
              InkWell(
                onTap: () => _toggle(g, o.id),
                borderRadius: r12,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: (_sel[g.id] ?? []).contains(o.id)
                        ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50)
                        : (dark ? ZK.cardDark : Colors.white),
                    borderRadius: r12,
                    border: Border.all(
                        color: (_sel[g.id] ?? []).contains(o.id) ? ZK.primary : (dark ? ZK.lineDark : ZK.line)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (_sel[g.id] ?? []).contains(o.id)
                            ? (g.single ? Icons.radio_button_checked : Icons.check_box)
                            : (g.single ? Icons.radio_button_unchecked : Icons.check_box_outline_blank),
                        size: 19,
                        color: (_sel[g.id] ?? []).contains(o.id)
                            ? ZK.primary
                            : (dark ? Colors.white38 : ZK.slate400),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(o.nama,
                            style: TextStyle(fontSize: 14, color: dark ? Colors.white : const Color(0xFF1E293B))),
                      ),
                      if (o.harga != 0)
                        Text('+ ${rupiah(o.harga)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ZK.primary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
