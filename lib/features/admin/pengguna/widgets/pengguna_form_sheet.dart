import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../produk/widgets/sheet_common.dart';

// Padanan _PenggunaFormSheet di admin_pengguna_page.dart lama — sheet
// mengumpulkan field lalu pop Map data mentah; create/update (via
// FormSubmitCubit<Pengguna>) dilakukan oleh AdminPenggunaPage pemanggilnya.
class PenggunaFormSheet extends StatefulWidget {
  final Pengguna? initial;
  const PenggunaFormSheet({super.key, this.initial});
  @override
  State<PenggunaFormSheet> createState() => _PenggunaFormSheetState();
}

class _PenggunaFormSheetState extends State<PenggunaFormSheet> {
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
