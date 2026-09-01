import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/katalog_cubit.dart';

// Padanan src/app/admin/katalog/page.tsx — link katalog publik toko + QR +
// banner. Domain publik ditebak dari base API (api.zonakasir.com ->
// zonakasir.com) karena mobile tidak punya window.location.origin seperti web.
const _publicOrigin = 'https://merchant.zonakasir.com';

class AdminKatalogPage extends StatelessWidget {
  const AdminKatalogPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => KatalogCubit(),
        child: const _AdminKatalogView(),
      );
}

class _AdminKatalogView extends StatefulWidget {
  const _AdminKatalogView();
  @override
  State<_AdminKatalogView> createState() => _AdminKatalogViewState();
}

class _AdminKatalogViewState extends State<_AdminKatalogView> {
  final _slug = TextEditingController();
  bool _synced = false;

  @override
  void dispose() {
    _slug.dispose();
    super.dispose();
  }

  String _url() => _slug.text.trim().isEmpty ? '' : '$_publicOrigin/store/${_slug.text.trim()}';

  Future<void> _uploadBanner(BuildContext context) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    try {
      await context.read<KatalogCubit>().uploadBanner(x.path);
      if (context.mounted) toastOk(context, 'Banner diperbarui');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> _saveSlug(BuildContext context) async {
    try {
      await context.read<KatalogCubit>().saveSlug(_slug.text.trim());
      if (context.mounted) {
        setState(() => _slug.text = context.read<KatalogCubit>().state.slug);
        toastOk(context, 'Link katalog disimpan');
      }
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _url()));
    toastOk(context, 'Link disalin');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    return BlocConsumer<KatalogCubit, KatalogState>(
      listener: (context, s) {
        if (s.status == KatalogStatus.ready && !_synced) {
          _synced = true;
          _slug.text = s.slug;
        }
        if (s.status == KatalogStatus.error && s.error != null) {
          toastError(context, s.error!);
        }
      },
      builder: (context, s) {
        if (s.status == KatalogStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: ZK.primary));
        }
        final url = _url();
        return SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _card(dark, child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Link katalog', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 10),
                    if (url.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: dark ? ZK.bgDark : ZK.background, borderRadius: r12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: ZK.primary)),
                            ),
                            IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _copy(context),
                                icon: Icon(Icons.copy, size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('Atur slug di bawah untuk membuat link.',
                            style: TextStyle(fontSize: 12, color: muted)),
                      ),
                    _fieldLabel('Slug (alamat link)', dark),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _slug,
                            style: TextStyle(color: fg),
                            decoration: _sheetInput('nama-toko-anda', dark: dark),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: s.savingSlug ? null : () => _saveSlug(context),
                            style: FilledButton.styleFrom(
                                backgroundColor: ZK.primary,
                                shape: const RoundedRectangleBorder(borderRadius: r12)),
                            child: s.savingSlug
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Hanya huruf kecil, angka, dan tanda hubung. Contoh: kopi-senja.',
                        style: TextStyle(fontSize: 11, color: muted)),
                  ],
                ),
              )),
              if (url.isNotEmpty) ...[
                const SizedBox(height: 14),
                _card(dark, child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: r12,
                        child: Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&margin=8&data=${Uri.encodeComponent(url)}',
                          height: 90,
                          width: 90,
                          errorBuilder: (_, __, ___) => Container(
                              height: 90, width: 90, color: dark ? ZK.bgDark : ZK.background,
                              child: const Icon(Icons.qr_code, color: ZK.slate400)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.qr_code, size: 15, color: ZK.primary),
                              const SizedBox(width: 6),
                              Text('QR Katalog',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                            ]),
                            const SizedBox(height: 4),
                            Text('Pengunjung scan QR ini untuk membuka katalog toko Anda.',
                                style: TextStyle(fontSize: 11.5, color: muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 14),
              _card(dark, child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Banner katalog', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: r14,
                      child: s.bannerUrl != null
                          ? Image.network(s.bannerUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
                          : Container(
                              height: 140,
                              width: double.infinity,
                              color: dark ? ZK.bgDark : ZK.background,
                              alignment: Alignment.center,
                              child: Text('Belum ada banner', style: TextStyle(fontSize: 13, color: muted)),
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: s.uploading ? null : () => _uploadBanner(context),
                      icon: s.uploading
                          ? const SizedBox(
                              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text(s.uploading ? 'Mengunggah...' : 'Unggah banner'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.primary,
                          side: const BorderSide(color: ZK.brand200),
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                    const SizedBox(height: 8),
                    Text('Logo toko diambil dari Pengaturan; produk & kategori otomatis tampil di katalog.',
                        style: TextStyle(fontSize: 11, color: muted)),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _card(bool dark, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: child,
      );

  Widget _fieldLabel(String text, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white70 : const Color(0xFF334155))),
      );

  InputDecoration _sheetInput(String hint, {bool dark = false}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
        filled: true,
        fillColor: dark ? ZK.bgDark : Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: r12, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: r12, borderSide: BorderSide(color: ZK.primary, width: 1.6)),
      );
}
