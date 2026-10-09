import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/sheet_common.dart';

class GroupFormSheet extends StatefulWidget {
  final ModifierGroup? initial;
  const GroupFormSheet({super.key, this.initial});
  @override
  State<GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<GroupFormSheet> {
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
