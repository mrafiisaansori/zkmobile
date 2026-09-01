import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/user/page.tsx — manajemen akun kasir & gudang.
// Level 1=Admin (tidak dikelola di sini), 2=Kasir, 3=Gudang.
class AdminPenggunaPage extends StatefulWidget {
  const AdminPenggunaPage({super.key});
  @override
  State<AdminPenggunaPage> createState() => _AdminPenggunaPageState();
}

class _AdminPenggunaPageState extends State<AdminPenggunaPage> {
  List<Pengguna> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.pengguna();
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Pengguna? item}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PenggunaFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await Api.createPengguna(result);
        if (mounted) toastOk(context, 'Pengguna ditambahkan');
      } else {
        await Api.updatePengguna(item.id, result);
        if (mounted) toastOk(context, 'Pengguna diperbarui');
      }
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Pengguna item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus pengguna?', message: 'Hapus akun "${item.nama}"?', danger: true);
    if (!ok) return;
    try {
      await Api.deletePengguna(item.id);
      if (mounted) toastOk(context, 'Pengguna dihapus');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _resetPassword(Pengguna item) async {
    final ok = await confirmDialog(context,
        title: 'Reset password?',
        message:
            'Buat password baru acak untuk "${item.nama}"? Password lama tidak bisa dipakai lagi setelah ini.');
    if (!ok) return;
    try {
      final res = await Api.resetPenggunaPassword(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: r14),
          title: const Text('Password baru',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Password baru untuk akun ${res['username']}. Catat sekarang — hanya tampil sekali.',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              SelectableText('${res['password']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
            ],
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(c),
                style: FilledButton.styleFrom(backgroundColor: ZK.primary),
                child: const Text('Selesai')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
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
                label: const Text('Tambah Pengguna'),
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
                        icon: Icons.manage_accounts_outlined,
                        title: 'Belum ada pengguna',
                        description: 'Tambah akun kasir.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final p = _data[i];
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
                                    child: const Icon(Icons.manage_accounts_outlined,
                                        color: ZK.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                        const SizedBox(height: 2),
                                        Text('${p.username} · ${p.roleLabel}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: muted)),
                                      ],
                                    ),
                                  ),
                                  if (p.level != 1)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _resetPassword(p),
                                            tooltip: 'Reset password',
                                            icon: Icon(Icons.key_outlined,
                                                size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _openForm(item: p),
                                            icon: Icon(Icons.edit_outlined,
                                                size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _hapus(p),
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

class _PenggunaFormSheet extends StatefulWidget {
  final Pengguna? initial;
  const _PenggunaFormSheet({this.initial});
  @override
  State<_PenggunaFormSheet> createState() => _PenggunaFormSheetState();
}

class _PenggunaFormSheetState extends State<_PenggunaFormSheet> {
  late final _nama = TextEditingController(text: widget.initial?.nama ?? '');
  late final _username = TextEditingController(text: widget.initial?.username ?? '');
  final _password = TextEditingController();
  late final _telp = TextEditingController(text: widget.initial?.telp ?? '');
  late int _level = widget.initial?.level == 3 ? 3 : 2;

  @override
  void dispose() {
    _nama.dispose();
    _username.dispose();
    _password.dispose();
    _telp.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty || _username.text.trim().isEmpty) {
      toastError(context, 'Nama dan username wajib diisi');
      return;
    }
    if (widget.initial == null && _password.text.trim().isEmpty) {
      toastError(context, 'Password wajib diisi');
      return;
    }
    Navigator.pop(context, {
      'nama': _nama.text.trim(),
      'username': _username.text.trim(),
      if (_password.text.trim().isNotEmpty) 'password': _password.text.trim(),
      'level': _level,
      'telp': _telp.text.trim(),
    });
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
                title: widget.initial == null ? 'Tambah Pengguna' : 'Ubah Pengguna',
                subtitle: 'Akun staff kasir',
                icon: Icons.manage_accounts_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Nama lengkap'),
                      TextField(
                          controller: _nama,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Nama pengguna', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Username'),
                      TextField(
                          controller: _username,
                          autocorrect: false,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Username login', dark: dark)),
                      if (widget.initial == null) ...[
                        const SizedBox(height: 14),
                        const FieldLabel('Password'),
                        TextField(
                            controller: _password,
                            obscureText: true,
                            style: TextStyle(color: dark ? Colors.white : ZK.ink),
                            decoration: sheetInput('Password awal', dark: dark)),
                      ],
                      const SizedBox(height: 14),
                      const FieldLabel('Role'),
                      _roleChip('Kasir', 2, dark),
                      const SizedBox(height: 6),
                      Text('Kasir: akses POS, Open Bill, dan Riwayat transaksi.',
                          style: TextStyle(fontSize: 11.5, color: dark ? Colors.white54 : ZK.slate400)),
                      const SizedBox(height: 14),
                      const FieldLabel('No. Telp (opsional)'),
                      TextField(
                          controller: _telp,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('081234567890', dark: dark)),
                      const SizedBox(height: 18),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label, int level, bool dark) {
    final active = _level == level;
    return GestureDetector(
      onTap: () => setState(() => _level = level),
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
