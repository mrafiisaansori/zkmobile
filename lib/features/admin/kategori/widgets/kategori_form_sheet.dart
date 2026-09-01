import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../produk/widgets/sheet_common.dart';

// Padanan _KategoriFormSheet di admin_kategori_page.dart lama — sheet cuma
// mengumpulkan input teks lalu pop hasilnya; create/update (dibungkus
// FormSubmitCubit<Kategori>) dilakukan oleh AdminKategoriPage pemanggilnya,
// sama seperti pola lama (sheet tidak tahu soal API).
class KategoriFormSheet extends StatefulWidget {
  final String? initial;
  const KategoriFormSheet({super.key, this.initial});
  @override
  State<KategoriFormSheet> createState() => _KategoriFormSheetState();
}

class _KategoriFormSheetState extends State<KategoriFormSheet> {
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
                title: widget.initial == null ? 'Tambah Kategori' : 'Ubah Kategori',
                subtitle: 'Nama kategori produk',
                icon: Icons.sell_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('Nama kategori'),
                    TextField(
                        controller: _c,
                        autofocus: true,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. Makanan, Minuman', dark: dark)),
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
