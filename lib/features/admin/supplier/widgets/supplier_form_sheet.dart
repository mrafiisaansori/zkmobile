import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/sheet_common.dart';

// Padanan _SupplierFormSheet di admin_supplier_page.dart lama — sheet
// mengumpulkan field lalu pop Map data mentah; create/update (via
// FormSubmitCubit<Supplier>) dilakukan oleh AdminSupplierPage pemanggilnya.
class SupplierFormSheet extends StatefulWidget {
  final Supplier? initial;
  const SupplierFormSheet({super.key, this.initial});
  @override
  State<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<SupplierFormSheet> {
  late final _nama = TextEditingController(text: widget.initial?.nama ?? '');
  late final _telp = TextEditingController(text: widget.initial?.noTelp ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _alamat = TextEditingController(text: widget.initial?.alamat ?? '');
  late final _catatan = TextEditingController(text: widget.initial?.catatan ?? '');
  late bool _aktif = (widget.initial?.status ?? 1) == 1;

  @override
  void dispose() {
    _nama.dispose();
    _telp.dispose();
    _email.dispose();
    _alamat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) {
      toastError(context, 'Nama supplier wajib diisi');
      return;
    }
    Navigator.pop(context, {
      'nama': _nama.text.trim(),
      'no_telp': _telp.text.trim(),
      'email': _email.text.trim(),
      'alamat': _alamat.text.trim(),
      'catatan': _catatan.text.trim(),
      'status': _aktif ? 1 : 0,
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
                title: widget.initial == null ? 'Tambah Supplier' : 'Ubah Supplier',
                subtitle: 'Data supplier barang',
                icon: Icons.local_shipping_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Nama supplier'),
                      TextField(
                          controller: _nama,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. PT Sumber Rejeki', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('No. Telepon / WhatsApp'),
                      TextField(
                          controller: _telp,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('081234567890', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Email (opsional)'),
                      TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. supplier@email.com', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Alamat'),
                      TextField(
                          controller: _alamat,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Alamat supplier', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Catatan (opsional)'),
                      TextField(
                          controller: _catatan,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Catatan tambahan', dark: dark)),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _aktif,
                        onChanged: (v) => setState(() => _aktif = v),
                        activeThumbColor: ZK.primary,
                        title: Text('Aktif',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : ZK.ink)),
                      ),
                      const SizedBox(height: 8),
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
}
