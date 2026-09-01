import 'dart:async';
import 'package:flutter/material.dart';
import 'admin_produk_form_page.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/produk/page.tsx — master data produk. Import massal,
// cetak label barcode, dan riwayat stok di web sengaja tidak diikutkan
// (fitur sekunder, bisa ditambah belakangan) — fokus CRUD + varian.
class AdminProdukPage extends StatefulWidget {
  const AdminProdukPage({super.key});
  @override
  State<AdminProdukPage> createState() => _AdminProdukPageState();
}

class _AdminProdukPageState extends State<AdminProdukPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<Produk> _data = [];
  List<Kategori> _kategori = [];
  bool _loading = true, _loadingMore = false, _lastPage = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
    Api.kategori().then((k) {
      if (mounted) setState(() => _kategori = k);
    }).catchError((_) {});
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    setState(() => append ? _loadingMore = true : _loading = true);
    try {
      final page = append ? _page + 1 : 1;
      final res = await Api.produk(search: _search.text, page: page);
      if (!mounted) return;
      setState(() {
        if (append) {
          final seen = _data.map((p) => p.id).toSet();
          _data.addAll(res.where((p) => !seen.contains(p.id)));
        } else {
          _data = res;
        }
        _page = page;
        _lastPage = res.length < 30;
      });
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => append ? _loadingMore = false : _loading = false);
    }
  }

  void _loadMore() {
    if (_loading || _loadingMore || _lastPage) return;
    _load(append: true);
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load());
  }

  Future<void> _tambah() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AdminProdukFormPage()));
    if (ok == true) _load();
  }

  Future<void> _ubah(Produk p) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AdminProdukFormPage(produk: p)));
    if (ok == true) _load();
  }

  Future<void> _hapus(Produk p) async {
    final ok = await confirmDialog(context,
        title: 'Hapus produk?',
        message: 'Hapus "${p.nama}"? Tindakan ini tidak bisa dibatalkan.',
        danger: true);
    if (!ok) return;
    try {
      await Api.deleteProduk(p.id);
      if (mounted) toastOk(context, 'Produk dihapus');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _kelolaVarian(Produk p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VarianSheet(produk: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearch,
                      style: TextStyle(color: dark ? Colors.white : ZK.ink),
                      decoration: InputDecoration(
                        hintText: 'Cari produk atau barcode...',
                        hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: dark ? Colors.white54 : ZK.slate400),
                        filled: true,
                        fillColor: dark ? ZK.cardDark : Colors.white,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: r12, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius: r12, borderSide: BorderSide(color: ZK.primary, width: 1.6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _tambah,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary,
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : _data.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Belum ada produk',
                        description: 'Tambah produk untuk mulai berjualan.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: () => _load(),
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _data.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: ZK.primary))),
                              );
                            }
                            final p = _data[i];
                            final kategoriNama =
                                _kategori.where((k) => k.id == p.idKategori).firstOrNull?.deskripsi;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dark ? ZK.cardDark : Colors.white,
                                borderRadius: r14,
                                border: Border.all(color: lineColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ProductThumb(url: p.foto, size: 52),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                        const SizedBox(height: 2),
                                        Text(
                                            [
                                              if (kategoriNama != null) kategoriNama,
                                              rupiah(p.hargaJual),
                                            ].join(' · '),
                                            style: TextStyle(fontSize: 12, color: muted)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: p.stok <= 0
                                                  ? ZK.rose50
                                                  : p.stok <= 10
                                                      ? ZK.amber50
                                                      : (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50),
                                              borderRadius: BorderRadius.circular(999)),
                                          child: Text('Stok ${p.stok}',
                                              style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: p.stok <= 0
                                                      ? ZK.rose
                                                      : p.stok <= 10
                                                          ? ZK.amber700
                                                          : (dark ? Colors.white : ZK.brand700))),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _kelolaVarian(p),
                                          tooltip: 'Varian',
                                          icon: Icon(Icons.layers_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _ubah(p),
                                          icon: Icon(Icons.edit_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _hapus(p),
                                          icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// Assign grup varian ke produk (checkbox list) — padanan modal "Varian" di web.
class _VarianSheet extends StatefulWidget {
  final Produk produk;
  const _VarianSheet({required this.produk});
  @override
  State<_VarianSheet> createState() => _VarianSheetState();
}

class _VarianSheetState extends State<_VarianSheet> {
  List<ModifierGroup> _all = [];
  List<int> _selected = [];
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results =
          await Future.wait([Api.modifierGroups(), Api.modifierFor(widget.produk.id)]);
      if (!mounted) return;
      setState(() {
        _all = results[0];
        _selected = results[1].map((g) => g.id).toList();
      });
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    try {
      await Api.setProductModifierGroups(widget.produk.id, _selected);
      if (mounted) {
        toastOk(context, 'Varian produk disimpan');
        Navigator.pop(context);
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
                title: 'Varian - ${widget.produk.nama}',
                subtitle: 'Pilih grup varian yang berlaku',
                icon: Icons.layers_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: ZK.primary)),
                )
              else if (_all.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Belum ada grup varian. Buat dulu di menu Varian.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: dark ? Colors.white54 : ZK.slate400)),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final g in _all)
                          CheckboxListTile(
                            value: _selected.contains(g.id),
                            onChanged: (v) => setState(() =>
                                v == true ? _selected.add(g.id) : _selected.remove(g.id)),
                            activeColor: ZK.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.nama,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white : ZK.ink)),
                            subtitle: Text('${g.options.length} opsi',
                                style: TextStyle(fontSize: 11, color: dark ? Colors.white54 : ZK.slate400)),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _simpan,
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
