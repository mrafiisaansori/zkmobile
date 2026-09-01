import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/satuan/page.tsx — CRUD satuan produk (Pcs, Kg, dst).
class AdminSatuanPage extends StatefulWidget {
  const AdminSatuanPage({super.key});
  @override
  State<AdminSatuanPage> createState() => _AdminSatuanPageState();
}

class _AdminSatuanPageState extends State<AdminSatuanPage> {
  List<Satuan> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.satuan();
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Satuan? item}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SatuanFormSheet(initial: item?.nama),
    );
    if (result == null || result.trim().isEmpty) return;
    try {
      if (item == null) {
        await Api.createSatuan(result.trim());
        if (mounted) toastOk(context, 'Satuan ditambahkan');
      } else {
        await Api.updateSatuan(item.id, result.trim());
        if (mounted) toastOk(context, 'Satuan diperbarui');
      }
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Satuan item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus satuan?', message: 'Hapus satuan "${item.nama}"?', danger: true);
    if (!ok) return;
    try {
      await Api.deleteSatuan(item.id);
      if (mounted) toastOk(context, 'Satuan dihapus');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: SizedBox(
              height: 46,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Satuan'),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : _data.isEmpty
                    ? const EmptyState(
                        icon: Icons.straighten_outlined,
                        title: 'Belum ada satuan',
                        description: 'mis. Pcs, Kg, Liter, Box.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final s = _data[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dark ? ZK.cardDark : Colors.white,
                                borderRadius: r14,
                                border: Border.all(color: lineColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                        color:
                                            dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.straighten_outlined,
                                        color: ZK.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(s.nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openForm(item: s),
                                          icon: Icon(Icons.edit_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _hapus(s),
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18, color: ZK.rose)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SatuanFormSheet extends StatefulWidget {
  final String? initial;
  const _SatuanFormSheet({this.initial});
  @override
  State<_SatuanFormSheet> createState() => _SatuanFormSheetState();
}

class _SatuanFormSheetState extends State<_SatuanFormSheet> {
  late final _c = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(
                title: widget.initial == null ? 'Tambah Satuan' : 'Ubah Satuan',
                subtitle: 'Satuan jual produk',
                icon: Icons.straighten_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('Nama satuan'),
                    TextField(
                        controller: _c,
                        autofocus: true,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. Pcs, Kg, Liter', dark: dark)),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, _c.text),
                        style: FilledButton.styleFrom(
                            backgroundColor: ZK.primary,
                            shape: const RoundedRectangleBorder(borderRadius: r12)),
                        child: const Text('Simpan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
