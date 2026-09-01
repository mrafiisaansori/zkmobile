import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/sheet_common.dart';
import '../data/varian_repository.dart';

// Kelola opsi satu grup: list opsi ada + form tambah opsi baru. Muncul di
// atas sheet grup (bukan modal terpisah dari daftar) sama seperti web.
class OptionsSheet extends StatefulWidget {
  final ModifierGroup group;
  final VarianRepository repo;
  final VoidCallback onChanged;
  const OptionsSheet({super.key, required this.group, required this.repo, required this.onChanged});
  @override
  State<OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<OptionsSheet> {
  late List<ModifierOption> _options = List.of(widget.group.options);
  final _nama = TextEditingController();
  final _harga = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    super.dispose();
  }

  Future<void> _tambah() async {
    if (_nama.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.repo.addOption(widget.group.id, _nama.text.trim(), int.tryParse(_harga.text) ?? 0);
      final fresh = await widget.repo.groups();
      final g = fresh.where((x) => x.id == widget.group.id).firstOrNull;
      if (mounted && g != null) setState(() => _options = g.options);
      _nama.clear();
      _harga.text = '0';
      widget.onChanged();
      if (mounted) toastOk(context, 'Opsi ditambahkan');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hapus(ModifierOption o) async {
    try {
      await widget.repo.deleteOption(o.id);
      setState(() => _options.removeWhere((x) => x.id == o.id));
      widget.onChanged();
      if (mounted) toastOk(context, 'Opsi dihapus');
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SheetHeader(
                title: 'Opsi - ${widget.group.nama}',
                subtitle: '${_options.length} opsi',
                icon: Icons.tune,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Expanded(
                child: _options.isEmpty
                    ? Center(
                        child: Text('Belum ada opsi',
                            style: TextStyle(fontSize: 13, color: dark ? Colors.white38 : ZK.slate400)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _options.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: dark ? ZK.lineDark : const Color(0xFFF1F5F9)),
                        itemBuilder: (_, i) {
                          final o = _options[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(o.nama,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: dark ? Colors.white : ZK.ink)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(o.harga > 0 ? '+${rupiah(o.harga)}' : 'Gratis',
                                    style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _hapus(o),
                                    icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                          controller: _nama,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Nama opsi', dark: dark)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                          controller: _harga,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Harga', dark: dark)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: FilledButton(
                        onPressed: _saving ? null : _tambah,
                        style: FilledButton.styleFrom(
                            backgroundColor: ZK.primary,
                            padding: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(borderRadius: r12)),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
