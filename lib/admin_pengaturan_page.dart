import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'main.dart';
import 'sheets.dart';
import 'theme.dart';

// Padanan src/app/admin/pengaturan/{page,pajak,pembayaran}.tsx — 3 sub-area
// web (identitas toko, pajak, QRIS) digabung jadi 3 tab di satu halaman
// mobile, dihubungkan lewat SettingsTabs di web.
class AdminPengaturanPage extends StatefulWidget {
  const AdminPengaturanPage({super.key});
  @override
  State<AdminPengaturanPage> createState() => _AdminPengaturanPageState();
}

class _AdminPengaturanPageState extends State<AdminPengaturanPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                _tabChip('Toko', 0, dark),
                const SizedBox(width: 8),
                _tabChip('Pajak', 1, dark),
                const SizedBox(width: 8),
                _tabChip('Pembayaran', 2, dark),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [_TokoTab(), _PajakTab(), _PembayaranTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int i, bool dark) {
    final active = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
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
      ),
    );
  }
}

Widget _card(bool dark, {required Widget child}) => Container(
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r14,
        border: Border.all(color: dark ? ZK.lineDark : ZK.line),
      ),
      child: child,
    );

// ===== Tab 1: identitas toko + logo =====
class _TokoTab extends StatefulWidget {
  const _TokoTab();
  @override
  State<_TokoTab> createState() => _TokoTabState();
}

class _TokoTabState extends State<_TokoTab> {
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _telp = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  String? _logoUrl;
  bool _loading = true, _saving = false, _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _telp.dispose();
    _email.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await Api.identitas();
      if (mounted) {
        setState(() {
          _nama.text = '${d['NAMA'] ?? ''}';
          _alamat.text = '${d['ALAMAT'] ?? ''}';
          _telp.text = '${d['NO_TELP'] ?? ''}';
          _email.text = '${d['EMAIL'] ?? ''}';
          _website.text = '${d['WEBSITE'] ?? ''}';
          _logoUrl = d['LOGO_URL'] as String?;
        });
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadLogo() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final d = await Api.uploadIdentitasLogo(x.path);
      if (mounted) {
        setState(() => _logoUrl = d['LOGO_URL'] as String?);
        toastOk(context, 'Logo toko diperbarui');
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await Api.updateIdentitas(
        nama: _nama.text.trim(),
        alamat: _alamat.text.trim(),
        noTelp: _telp.text.trim(),
        email: _email.text.trim(),
        website: _website.text.trim(),
      );
      if (mounted) toastOk(context, 'Pengaturan disimpan');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    if (_loading) return const Center(child: CircularProgressIndicator(color: ZK.primary));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _card(dark, child: Padding(
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
                    child: _logoUrl != null
                        ? Image.network(_logoUrl!, height: 72, width: 72, fit: BoxFit.contain)
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
                      onPressed: _uploading ? null : _uploadLogo,
                      icon: _uploading
                          ? const SizedBox(
                              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text(_uploading ? 'Mengunggah...' : 'Unggah logo'),
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
        _card(dark, child: Padding(
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
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: _saving
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
  }
}

// ===== Tab 2: pajak (PRO) =====
class _PajakTab extends StatefulWidget {
  const _PajakTab();
  @override
  State<_PajakTab> createState() => _PajakTabState();
}

class _PajakTabState extends State<_PajakTab> {
  bool _ppnOn = false, _serviceOn = false, _saving = false;
  final _ppnPersen = TextEditingController(text: '0');
  final _servicePersen = TextEditingController(text: '0');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Session.isPro) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _ppnPersen.dispose();
    _servicePersen.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await Api.tax();
      if (mounted && t != null) {
        setState(() {
          _ppnOn = t.ppnOn;
          _serviceOn = t.serviceOn;
          _ppnPersen.text = '${t.ppnPersen}';
          _servicePersen.text = '${t.servicePersen}';
        });
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await Api.updateTax(
        ppnEnabled: _ppnOn,
        ppnPersen: num.tryParse(_ppnPersen.text) ?? 0,
        serviceEnabled: _serviceOn,
        servicePersen: num.tryParse(_servicePersen.text) ?? 0,
      );
      if (mounted) toastOk(context, 'Pengaturan pajak disimpan');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;

    if (!Session.isPro) {
      return SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_outlined, size: 44, color: ZK.amber700),
                const SizedBox(height: 14),
                Text('Pajak & Service Charge tersedia mulai paket PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 8),
                Text('Atur PPN dan biaya layanan secara terpisah agar perhitungan checkout dan struk tetap konsisten.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: muted)),
              ],
            ),
          ),
        ),
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator(color: ZK.primary));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _card(dark, child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _toggleRow('Aktifkan PPN', _ppnOn, (v) => setState(() => _ppnOn = v), dark),
              if (_ppnOn) ...[
                const SizedBox(height: 12),
                const FieldLabel('Persentase PPN (%)'),
                TextField(
                    controller: _ppnPersen,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: fg),
                    decoration: sheetInput('0', dark: dark)),
              ],
              const SizedBox(height: 16),
              _toggleRow('Aktifkan Service Charge', _serviceOn, (v) => setState(() => _serviceOn = v), dark),
              if (_serviceOn) ...[
                const SizedBox(height: 12),
                const FieldLabel('Persentase Service Charge (%)'),
                TextField(
                    controller: _servicePersen,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: fg),
                    decoration: sheetInput('0', dark: dark)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: _saving
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
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged, bool dark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dark ? ZK.bgDark : ZK.background,
          borderRadius: r12,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.slate600)),
            ),
            Switch(value: value, onChanged: onChanged, activeThumbColor: ZK.primary),
          ],
        ),
      );
}

// ===== Tab 3: QRIS =====
class _PembayaranTab extends StatefulWidget {
  const _PembayaranTab();
  @override
  State<_PembayaranTab> createState() => _PembayaranTabState();
}

class _PembayaranTabState extends State<_PembayaranTab> {
  final _merchantName = TextEditingController();
  final _nmid = TextEditingController();
  bool _isActive = false;
  String? _imageUrl;
  String? _newImagePath;
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _merchantName.dispose();
    _nmid.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final q = await Api.qris();
      if (mounted && q != null) {
        setState(() {
          _merchantName.text = q.merchantName ?? '';
          _nmid.text = q.nmid ?? '';
          _isActive = q.isActive;
          _imageUrl = q.imageUrl;
        });
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _newImagePath = x.path);
  }

  Future<void> _submit() async {
    if (_isActive && _imageUrl == null && _newImagePath == null) {
      toastError(context, 'Upload gambar QRIS terlebih dahulu sebelum mengaktifkan');
      return;
    }
    setState(() => _saving = true);
    try {
      final q = await Api.updateQris(
        merchantName: _merchantName.text.trim(),
        nmid: _nmid.text.trim(),
        isActive: _isActive,
        filePath: _newImagePath,
      );
      if (mounted) {
        setState(() {
          _imageUrl = q.imageUrl;
          _newImagePath = null;
        });
        toastOk(context, 'Pengaturan QRIS disimpan');
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    if (_loading) return const Center(child: CircularProgressIndicator(color: ZK.primary));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _card(dark, child: Padding(
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
                        Text('QRIS statis — pelanggan scan, kasir konfirmasi manual.',
                            style: TextStyle(fontSize: 11.5, color: muted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _isActive ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50) : ZK.rose50,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(_isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isActive ? (dark ? Colors.white : ZK.brand700) : ZK.rose)),
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
                        : _imageUrl != null
                            ? Image.network(_imageUrl!, height: 110, width: 110, fit: BoxFit.contain)
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
                          label: Text(_imageUrl == null ? 'Pilih gambar' : 'Ganti gambar'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: ZK.primary,
                              side: const BorderSide(color: ZK.brand200),
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                        ),
                        const SizedBox(height: 6),
                        Text('Format jpg, jpeg, png, webp. Maks 2MB.',
                            style: TextStyle(fontSize: 10.5, color: muted)),
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
                                  fontSize: 13.5, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.slate600)),
                          Text('Jika nonaktif, metode QRIS tidak tersedia di kasir.',
                              style: TextStyle(fontSize: 11, color: muted)),
                        ],
                      ),
                    ),
                    Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: ZK.primary),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: _saving
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
  }
}
