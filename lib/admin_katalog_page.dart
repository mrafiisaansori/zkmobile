import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'main.dart';
import 'sheets.dart';
import 'theme.dart';

// Padanan src/app/admin/katalog/page.tsx — link katalog publik toko + QR +
// banner. Domain publik ditebak dari base API (api.zonakasir.com ->
// zonakasir.com) karena mobile tidak punya window.location.origin seperti web.
const _publicOrigin = 'https://merchant.zonakasir.com';

class AdminKatalogPage extends StatefulWidget {
  const AdminKatalogPage({super.key});
  @override
  State<AdminKatalogPage> createState() => _AdminKatalogPageState();
}

class _AdminKatalogPageState extends State<AdminKatalogPage> {
  final _slug = TextEditingController();
  String? _bannerUrl;
  bool _loading = true, _savingSlug = false, _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _slug.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([Api.merchantMe(), Api.identitas()]);
      final merchant = results[0];
      final identitas = results[1];
      if (mounted) {
        setState(() {
          _slug.text = '${merchant['SLUG'] ?? ''}';
          _bannerUrl = identitas['BANNER_URL'] as String?;
        });
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _url => _slug.text.trim().isEmpty ? '' : '$_publicOrigin/store/${_slug.text.trim()}';

  Future<void> _saveSlug() async {
    setState(() => _savingSlug = true);
    try {
      final m = await Api.updateMerchantSlug(_slug.text.trim());
      if (mounted) {
        setState(() => _slug.text = '${m['SLUG'] ?? ''}');
        toastOk(context, 'Link katalog disimpan');
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _savingSlug = false);
    }
  }

  Future<void> _uploadBanner() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final d = await Api.uploadIdentitasBanner(x.path);
      if (mounted) {
        setState(() => _bannerUrl = d['BANNER_URL'] as String?);
        toastOk(context, 'Banner diperbarui');
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _url));
    toastOk(context, 'Link disalin');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: ZK.primary));
    }
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
                if (_url.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: dark ? ZK.bgDark : ZK.background, borderRadius: r12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: ZK.primary)),
                        ),
                        IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: _copy,
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
                const FieldLabel('Slug (alamat link)'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _slug,
                        style: TextStyle(color: fg),
                        decoration: sheetInput('nama-toko-anda', dark: dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _savingSlug ? null : _saveSlug,
                        style: FilledButton.styleFrom(
                            backgroundColor: ZK.primary,
                            shape: const RoundedRectangleBorder(borderRadius: r12)),
                        child: _savingSlug
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
          if (_url.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(dark, child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: r12,
                    child: Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=200x200&margin=8&data=${Uri.encodeComponent(_url)}',
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
                  child: _bannerUrl != null
                      ? Image.network(_bannerUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
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
                  onPressed: _uploading ? null : _uploadBanner,
                  icon: _uploading
                      ? const SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(_uploading ? 'Mengunggah...' : 'Unggah banner'),
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
  }

  Widget _card(bool dark, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: child,
      );
}
