import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/pembayaran_cubit.dart';
import 'sheet_field.dart';

// ===== Tab 3: QRIS — padanan _PembayaranTab lama =====
class PembayaranTab extends StatelessWidget {
  const PembayaranTab({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => PembayaranCubit(),
        child: const _PembayaranTabView(),
      );
}

class _PembayaranTabView extends StatefulWidget {
  const _PembayaranTabView();
  @override
  State<_PembayaranTabView> createState() => _PembayaranTabViewState();
}

class _PembayaranTabViewState extends State<_PembayaranTabView> {
  final _merchantName = TextEditingController();
  final _nmid = TextEditingController();
  String? _newImagePath;
  bool _synced = false;

  @override
  void dispose() {
    _merchantName.dispose();
    _nmid.dispose();
    super.dispose();
  }

  void _syncControllers(PembayaranState s) {
    _merchantName.text = s.merchantName;
    _nmid.text = s.nmid;
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _newImagePath = x.path);
  }

  Future<void> _submit(BuildContext context, PembayaranState s) async {
    if (s.isActive && s.imageUrl == null && _newImagePath == null) {
      toastError(context, 'Upload gambar QRIS terlebih dahulu sebelum mengaktifkan');
      return;
    }
    try {
      await context.read<PembayaranCubit>().save(
            merchantName: _merchantName.text.trim(),
            nmid: _nmid.text.trim(),
            filePath: _newImagePath,
          );
      if (context.mounted) {
        setState(() => _newImagePath = null);
        toastOk(context, 'Pengaturan QRIS disimpan');
      }
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    return BlocConsumer<PembayaranCubit, PembayaranState>(
      listener: (context, s) {
        if (s.status == PembayaranStatus.ready && !_synced) {
          _synced = true;
          _syncControllers(s);
        }
        if (s.status == PembayaranStatus.error && s.error != null) {
          toastError(context, s.error!);
        }
      },
      builder: (context, s) {
        if (s.status == PembayaranStatus.loading) {
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pembayaran QRIS',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                            const SizedBox(height: 2),
                            Text('QRIS statis: pelanggan scan, kasir konfirmasi manual.',
                                style: TextStyle(fontSize: 12, color: muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: s.isActive ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50) : ZK.rose50,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(s.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: s.isActive ? (dark ? Colors.white : ZK.brand700) : ZK.rose)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: r14,
                        child: _newImagePath != null
                            ? Image.file(File(_newImagePath!), height: 110, width: 110, fit: BoxFit.contain)
                            : s.imageUrl != null
                                ? Image.network(s.imageUrl!, height: 110, width: 110, fit: BoxFit.contain)
                                : Container(
                                    height: 110,
                                    width: 110,
                                    color: dark ? ZK.bgDark : ZK.background,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.qr_code, color: ZK.slate400, size: 32),
                                  ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                              label: Text(s.imageUrl == null ? 'Pilih gambar' : 'Ganti gambar'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: ZK.primary,
                                  side: const BorderSide(color: ZK.brand200),
                                  shape: const RoundedRectangleBorder(borderRadius: r12)),
                            ),
                            const SizedBox(height: 6),
                            Text('Format jpg, jpeg, png, webp. Maks 2MB.',
                                style: TextStyle(fontSize: 11, color: muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Nama merchant'),
                  TextField(
                      controller: _merchantName,
                      style: TextStyle(color: fg),
                      decoration: sheetInput('Nama yang tampil di QRIS', dark: dark)),
                  const SizedBox(height: 14),
                  const FieldLabel('NMID / ID QRIS (opsional)'),
                  TextField(
                      controller: _nmid,
                      style: TextStyle(color: fg),
                      decoration: sheetInput('contoh: ID1024xxxxxxxx', dark: dark)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: dark ? ZK.bgDark : ZK.background,
                      borderRadius: r12,
                      border: Border.all(color: dark ? ZK.lineDark : ZK.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aktifkan QRIS',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.slate600)),
                              Text('Jika nonaktif, metode QRIS tidak tersedia di kasir.',
                                  style: TextStyle(fontSize: 11, color: muted)),
                            ],
                          ),
                        ),
                        Switch(
                            value: s.isActive,
                            onChanged: (v) => context.read<PembayaranCubit>().setActive(v),
                            activeThumbColor: ZK.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: s.saving ? null : () => _submit(context, s),
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
