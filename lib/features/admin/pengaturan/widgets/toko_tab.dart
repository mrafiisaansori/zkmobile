import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/toko_cubit.dart';
import 'sheet_field.dart';

// ===== Tab 1: identitas toko + logo — padanan _TokoTab lama =====
class TokoTab extends StatelessWidget {
  const TokoTab({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => TokoCubit(),
        child: const _TokoTabView(),
      );
}

class _TokoTabView extends StatefulWidget {
  const _TokoTabView();
  @override
  State<_TokoTabView> createState() => _TokoTabViewState();
}

class _TokoTabViewState extends State<_TokoTabView> {
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _telp = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  bool _synced = false;

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _telp.dispose();
    _email.dispose();
    _website.dispose();
    super.dispose();
  }

  void _syncControllers(TokoState s) {
    _nama.text = s.nama;
    _alamat.text = s.alamat;
    _telp.text = s.noTelp;
    _email.text = s.email;
    _website.text = s.website;
  }

  Future<void> _uploadLogo(BuildContext context) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    try {
      await context.read<TokoCubit>().uploadLogo(x.path);
      if (context.mounted) toastOk(context, 'Logo toko diperbarui');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> _submit(BuildContext context) async {
    try {
      await context.read<TokoCubit>().save(
            nama: _nama.text.trim(),
            alamat: _alamat.text.trim(),
            noTelp: _telp.text.trim(),
            email: _email.text.trim(),
            website: _website.text.trim(),
          );
      if (context.mounted) toastOk(context, 'Pengaturan disimpan');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    return BlocConsumer<TokoCubit, TokoState>(
      listener: (context, s) {
        if (s.status == TokoStatus.ready && !_synced) {
          _synced = true;
          _syncControllers(s);
        }
        if (s.status == TokoStatus.error && s.error != null) {
          toastError(context, s.error!);
        }
      },
      builder: (context, s) {
        if (s.status == TokoStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: ZK.primary));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            settingsCard(dark, child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logo toko', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: r14,
                        child: s.logoUrl != null
                            ? Image.network(s.logoUrl!, height: 72, width: 72, fit: BoxFit.contain)
                            : Container(
                                height: 72,
                                width: 72,
                                color: dark ? ZK.bgDark : ZK.background,
                                alignment: Alignment.center,
                                child: Text('Belum ada', style: TextStyle(fontSize: 10, color: muted)),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: s.uploading ? null : () => _uploadLogo(context),
                          icon: s.uploading
                              ? const SizedBox(
                                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: Text(s.uploading ? 'Mengunggah...' : 'Unggah logo'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: ZK.primary,
                              side: const BorderSide(color: ZK.brand200),
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Logo tampil di struk, QR menu, dan katalog online.',
                      style: TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            )),
            const SizedBox(height: 14),
            settingsCard(dark, child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Nama toko'),
                  TextField(controller: _nama, style: TextStyle(color: fg), decoration: sheetInput('Nama toko', dark: dark)),
                  const SizedBox(height: 14),
                  const FieldLabel('Alamat'),
                  TextField(controller: _alamat, style: TextStyle(color: fg), decoration: sheetInput('Alamat', dark: dark)),
                  const SizedBox(height: 14),
                  const FieldLabel('No. Telp'),
                  TextField(
                      controller: _telp,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: fg),
                      decoration: sheetInput('081234567890', dark: dark)),
                  const SizedBox(height: 14),
                  const FieldLabel('Email'),
                  TextField(controller: _email, style: TextStyle(color: fg), decoration: sheetInput('Email', dark: dark)),
                  const SizedBox(height: 14),
                  const FieldLabel('Website'),
                  TextField(controller: _website, style: TextStyle(color: fg), decoration: sheetInput('Website', dark: dark)),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: s.saving ? null : () => _submit(context),
                      style: FilledButton.styleFrom(
                          backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                      child: s.saving
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}
