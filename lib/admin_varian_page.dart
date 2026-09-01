import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/modifier/page.tsx — grup varian (ukuran, topping,
// dsb) + opsi per grup. Opsi dikelola lewat sheet terpisah, sama seperti web.
class AdminVarianPage extends StatefulWidget {
  const AdminVarianPage({super.key});
  @override
  State<AdminVarianPage> createState() => _AdminVarianPageState();
}

class _AdminVarianPageState extends State<AdminVarianPage> {
  List<ModifierGroup> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.modifierGroups();
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({ModifierGroup? item}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await Api.createModifierGroup(
            result['nama'] as String, result['tipe'] as String, result['wajib'] as bool);
        if (mounted) toastOk(context, 'Grup ditambahkan');
      } else {
        await Api.updateModifierGroup(
            item.id, result['nama'] as String, result['tipe'] as String, result['wajib'] as bool);
        if (mounted) toastOk(context, 'Grup diperbarui');
      }
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapusGroup(ModifierGroup item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus grup?',
        message: 'Hapus grup "${item.nama}" beserta semua opsinya?',
        danger: true);
    if (!ok) return;
    try {
      await Api.deleteModifierGroup(item.id);
      if (mounted) toastOk(context, 'Grup dihapus');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _kelolaOpsi(ModifierGroup item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionsSheet(group: item, onChanged: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    final tablet = isTablet(context);
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
                label: const Text('Tambah Grup'),
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
                        icon: Icons.layers_outlined,
                        title: 'Belum ada grup varian',
                        description: "Mis. buat grup 'Ukuran' dengan opsi S, M, L.")
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: tablet ? 2 : 1,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: tablet ? 2.4 : 2.6,
                          ),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final g = _data[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: dark ? ZK.cardDark : Colors.white,
                                borderRadius: r14,
                                border: Border.all(color: lineColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.layers_outlined, size: 16, color: ZK.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(g.nama,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                      ),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openForm(item: g),
                                          icon: Icon(Icons.edit_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _hapusGroup(g),
                                          icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                                    ],
                                  ),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _badge(g.single ? 'Pilih satu' : 'Pilih banyak',
                                          dark ? ZK.primary.withValues(alpha: 0.18) : ZK.brand50,
                                          dark ? Colors.white : ZK.brand700),
                                      if (g.wajib) _badge('Wajib', ZK.amber50, ZK.amber700),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${g.options.length} opsi',
                                      style: TextStyle(fontSize: 12, color: muted)),
                                  const Spacer(),
                                  SizedBox(
                                    height: 34,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _kelolaOpsi(g),
                                      icon: const Icon(Icons.tune, size: 15),
                                      label: const Text('Kelola opsi', style: TextStyle(fontSize: 12.5)),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: ZK.primary,
                                          side: const BorderSide(color: ZK.brand200),
                                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                                    ),
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

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
      );
}

class _GroupFormSheet extends StatefulWidget {
  final ModifierGroup? initial;
  const _GroupFormSheet({this.initial});
  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  late final _nama = TextEditingController(text: widget.initial?.nama ?? '');
  late String _tipe = widget.initial?.tipe ?? 'SINGLE';
  late bool _wajib = widget.initial?.wajib ?? false;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) {
      toastError(context, 'Nama grup wajib diisi');
      return;
    }
    Navigator.pop(context, {'nama': _nama.text.trim(), 'tipe': _tipe, 'wajib': _wajib});
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
                title: widget.initial == null ? 'Tambah Grup' : 'Ubah Grup',
                subtitle: 'Grup varian produk',
                icon: Icons.layers_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('Nama grup'),
                    TextField(
                        controller: _nama,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. Ukuran / Topping', dark: dark)),
                    const SizedBox(height: 14),
                    const FieldLabel('Tipe pilihan'),
                    Row(
                      children: [
                        Expanded(child: _tipeChip('Pilih satu', 'SINGLE', dark)),
                        const SizedBox(width: 8),
                        Expanded(child: _tipeChip('Pilih banyak', 'MULTI', dark)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _wajib,
                      onChanged: (v) => setState(() => _wajib = v),
                      activeThumbColor: ZK.primary,
                      title: Text('Wajib dipilih saat jual',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : ZK.ink)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _submit,
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

  Widget _tipeChip(String label, String tipe, bool dark) {
    final active = _tipe == tipe;
    return GestureDetector(
      onTap: () => setState(() => _tipe = tipe),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
          borderRadius: r12,
          border: Border.all(color: active ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
      ),
    );
  }
}

// Kelola opsi satu grup: list opsi ada + form tambah opsi baru. Muncul di
// atas sheet grup (bukan modal terpisah dari daftar) sama seperti web.
class _OptionsSheet extends StatefulWidget {
  final ModifierGroup group;
  final VoidCallback onChanged;
  const _OptionsSheet({required this.group, required this.onChanged});
  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
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
      await Api.addModifierOption(widget.group.id, _nama.text.trim(), int.tryParse(_harga.text) ?? 0);
      final fresh = await Api.modifierGroups();
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
      await Api.deleteModifierOption(o.id);
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
