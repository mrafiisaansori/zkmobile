import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shell/cubit/admin_shell_cubit.dart';
import '../../shell/widgets/admin_sidebar.dart';
import '../../../auth/screens/login_page.dart';
import '../data/produk_repository.dart';
import '../widgets/sheet_common.dart';

// Padanan components/forms/ProdukForm.tsx — halaman penuh (bukan sheet)
// karena jumlah field & preview foto butuh ruang lebih.
//
// Versi BLoC dari admin_produk_form_page.dart lama: create/update dibungkus
// FormSubmitCubit<Produk> alih-alih setState _saving manual.
class AdminProdukFormPage extends StatefulWidget {
  final ProdukRepository repo;
  final Produk? produk;
  const AdminProdukFormPage({super.key, required this.repo, this.produk});
  @override
  State<AdminProdukFormPage> createState() => _AdminProdukFormPageState();
}

class _AdminProdukFormPageState extends State<AdminProdukFormPage> {
  late final _nama = TextEditingController(text: widget.produk?.nama ?? '');
  late final _hargaBeli =
      TextEditingController(text: widget.produk != null ? '${widget.produk!.hargaBeli}' : '0');
  late final _hargaJual =
      TextEditingController(text: widget.produk != null ? '${widget.produk!.hargaJual}' : '0');
  late final _stok = TextEditingController(text: '0');
  late final _barcode = TextEditingController(text: widget.produk?.barcode ?? '');
  final _formCubit = FormSubmitCubit<Produk>();
  List<Kategori> _kategori = [];
  List<Satuan> _satuan = [];
  int? _idKategori, _idSatuan;
  File? _foto;
  bool _loadingRef = true;

  @override
  void initState() {
    super.initState();
    _idKategori = widget.produk?.idKategori;
    _idSatuan = widget.produk?.idSatuan;
    _loadRef();
  }

  Future<void> _loadRef() async {
    try {
      final results = await Future.wait([widget.repo.kategori(), widget.repo.satuan()]);
      if (!mounted) return;
      setState(() {
        _kategori = results[0] as List<Kategori>;
        _satuan = results[1] as List<Satuan>;
        if (_idKategori == null && _kategori.isNotEmpty) _idKategori = _kategori.first.id;
      });
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loadingRef = false);
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _hargaBeli.dispose();
    _hargaJual.dispose();
    _stok.dispose();
    _barcode.dispose();
    _formCubit.close();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _foto = File(x.path));
  }

  Future<void> _submit() async {
    if (_nama.text.trim().isEmpty) {
      toastError(context, 'Nama produk wajib diisi');
      return;
    }
    if (_idKategori == null) {
      toastError(context, 'Kategori wajib dipilih');
      return;
    }
    final editing = widget.produk != null;
    final saved = await _formCubit.submit(() => editing
        ? widget.repo.update(
            widget.produk!.id,
            nama: _nama.text.trim(),
            idKategori: _idKategori!,
            hargaBeli: parseRupiah(_hargaBeli.text),
            hargaJual: parseRupiah(_hargaJual.text),
            barcode: _barcode.text.trim(),
            idSatuan: _idSatuan,
            fotoPath: _foto?.path,
          )
        : widget.repo.create(
            nama: _nama.text.trim(),
            idKategori: _idKategori!,
            hargaBeli: parseRupiah(_hargaBeli.text),
            hargaJual: parseRupiah(_hargaJual.text),
            stok: int.tryParse(_stok.text) ?? 0,
            barcode: _barcode.text.trim(),
            idSatuan: _idSatuan,
            fotoPath: _foto?.path,
          ));
    if (!mounted) return;
    if (saved != null) {
      toastOk(context, editing ? 'Produk diperbarui' : 'Produk ditambahkan');
      Navigator.pop(context, true);
    } else if (_formCubit.state.error != null) {
      toastError(context, _formCubit.state.error!);
    }
  }

  Future<void> _logout() async {
    await Session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final editing = widget.produk != null;
    final hero = HeroShell(
        titleOverride: editing ? 'Ubah Produk' : 'Tambah Produk',
        subtitleOverride: 'Master data produk',
        child: SafeArea(
          top: false,
          bottom: false,
          child: _loadingRef
              ? const Center(child: CircularProgressIndicator(color: ZK.primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: r12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 18, color: fg),
                            const SizedBox(width: 6),
                            Text('Kembali',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(editing ? 'Ubah Produk' : 'Tambah Produk',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _pilihFoto,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: r14,
                              child: _foto != null
                                  ? Image.file(_foto!, height: 110, width: 110, fit: BoxFit.cover)
                                  : ProductThumb(url: widget.produk?.foto, size: 110),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration:
                                    const BoxDecoration(color: ZK.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Nama produk'),
                    TextField(
                        controller: _nama,
                        style: TextStyle(color: fg),
                        decoration: sheetInput('Nama produk', dark: dark)),
                    const SizedBox(height: 14),
                    const FieldLabel('Kategori'),
                    DropdownButtonFormField<int>(
                      initialValue: _idKategori,
                      isExpanded: true,
                      style: TextStyle(color: fg, fontSize: 14),
                      dropdownColor: dark ? ZK.cardDark : Colors.white,
                      decoration: sheetInput('Pilih kategori', dark: dark),
                      items: [
                        for (final k in _kategori)
                          DropdownMenuItem(value: k.id, child: Text(k.deskripsi)),
                      ],
                      onChanged: (v) => setState(() => _idKategori = v),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Harga beli'),
                              TextField(
                                  controller: _hargaBeli,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [RupiahInputFormatter()],
                                  style: TextStyle(color: fg),
                                  decoration: sheetInput('0', prefix: 'Rp ', dark: dark)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Harga jual'),
                              TextField(
                                  controller: _hargaJual,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [RupiahInputFormatter()],
                                  style: TextStyle(color: fg),
                                  decoration: sheetInput('0', prefix: 'Rp ', dark: dark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!editing) ...[
                      const SizedBox(height: 14),
                      const FieldLabel('Stok awal'),
                      TextField(
                          controller: _stok,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: fg),
                          decoration: sheetInput('0', dark: dark)),
                    ],
                    const SizedBox(height: 14),
                    const FieldLabel('Satuan (opsional)'),
                    DropdownButtonFormField<int?>(
                      initialValue: _idSatuan,
                      isExpanded: true,
                      style: TextStyle(color: fg, fontSize: 14),
                      dropdownColor: dark ? ZK.cardDark : Colors.white,
                      decoration: sheetInput('Pilih satuan', dark: dark),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('-')),
                        for (final s in _satuan) DropdownMenuItem(value: s.id, child: Text(s.nama)),
                      ],
                      onChanged: (v) => setState(() => _idSatuan = v),
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel('Barcode (opsional)'),
                    TextField(
                        controller: _barcode,
                        style: TextStyle(color: fg),
                        decoration: sheetInput('Barcode', dark: dark)),
                    const SizedBox(height: 22),
                    BlocBuilder<FormSubmitCubit<Produk>, FormSubmitState<Produk>>(
                      bloc: _formCubit,
                      builder: (context, state) => SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: state.status == FormStatus.submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                          child: state.status == FormStatus.submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(editing ? 'Simpan perubahan' : 'Tambah produk',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );

    if (isTablet(context)) {
      return Scaffold(
        backgroundColor: dark ? ZK.bgDark : ZK.background,
        body: Row(
          children: [
            AdminSidebar(
              selected: 4, // index Produk di grup Master Data
              onSelect: (i) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                AdminShellCubit.current?.select(i);
              },
              onLogout: _logout,
            ),
            Expanded(child: hero),
          ],
        ),
      );
    }
    return Scaffold(backgroundColor: dark ? ZK.bgDark : ZK.background, body: hero);
  }
}
