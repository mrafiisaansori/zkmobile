import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../produk/widgets/sheet_common.dart';

// Padanan _SatuanFormSheet di admin_satuan_page.dart lama — sheet cuma
// mengumpulkan input teks lalu pop hasilnya; create/update dilakukan oleh
// AdminSatuanPage pemanggilnya lewat FormSubmitCubit<Satuan>.
class SatuanFormSheet extends StatefulWidget {
  final String? initial;
  const SatuanFormSheet({super.key, this.initial});
  @override
  State<SatuanFormSheet> createState() => _SatuanFormSheetState();
}

class _SatuanFormSheetState extends State<SatuanFormSheet> {
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
