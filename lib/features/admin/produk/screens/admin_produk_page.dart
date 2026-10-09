import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../data/produk_repository.dart';
import '../widgets/varian_sheet.dart';
import 'admin_produk_form_page.dart';

// Padanan src/app/admin/produk/page.tsx — master data produk. Import massal,
// cetak label barcode, dan riwayat stok di web sengaja tidak diikutkan
// (fitur sekunder, bisa ditambah belakangan) — fokus CRUD + varian.
//
// Versi BLoC dari admin_produk_page.dart lama: list+search+paginate+delete
// dipindah ke ListCubit<Produk> generik, halaman ini cuma jadi consumer.
class AdminProdukPage extends StatefulWidget {
  const AdminProdukPage({super.key});
  @override
  State<AdminProdukPage> createState() => _AdminProdukPageState();
}

class _AdminProdukPageState extends State<AdminProdukPage> {
  final _repo = ProdukRepository();
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  late final ListCubit<Produk> _cubit;
  List<Kategori> _kategori = [];

  @override
  void initState() {
    super.initState();
    _cubit = ListCubit<Produk>(fetchPage: _repo.fetchPage, deleteItem: _repo.delete, pageSize: 30)
      ..load();
    _repo.kategori().then((k) {
      if (mounted) setState(() => _kategori = k);
    }).catchError((_) {});
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _cubit.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _cubit.load(search: _search.text));
  }

  Future<void> _tambah() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AdminProdukFormPage(repo: _repo)));
    if (ok == true) _cubit.refresh();
  }

  Future<void> _ubah(Produk p) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AdminProdukFormPage(repo: _repo, produk: p)));
    if (ok == true) _cubit.refresh();
  }

  Future<void> _hapus(Produk p) async {
    final ok = await confirmDialog(context,
        title: 'Hapus produk?',
        message: 'Hapus "${p.nama}"? Tindakan ini tidak bisa dibatalkan.',
        danger: true);
    if (!ok) return;
    final success = await _cubit.remove(p);
    if (!mounted) return;
    if (success) {
      toastOk(context, 'Produk dihapus');
    } else {
      final err = _cubit.state.error;
      if (err != null) toastError(context, err);
    }
  }

  Future<void> _kelolaVarian(Produk p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VarianSheet(produk: p, repo: _repo),
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
                        hintStyle: TextStyle(color: dark ? Colors.white60 : ZK.slate500, fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: dark ? Colors.white60 : ZK.slate400),
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
            child: BlocBuilder<ListCubit<Produk>, ListState<Produk>>(
              bloc: _cubit,
              builder: (context, state) {
                final loading = state.status == ListStatus.initial || state.status == ListStatus.loading;
                final loadingMore = state.status == ListStatus.loadingMore;
                if (loading) {
                  return const Center(child: CircularProgressIndicator(color: ZK.primary));
                }
                // Gagal muat beda dengan kosong: tampilkan sebab + muat ulang.
                if (state.status == ListStatus.error && state.items.isEmpty) {
                  return RError(
                      message: state.error ?? 'Periksa koneksi internet lalu muat ulang.',
                      onRetry: () => _cubit.refresh());
                }
                if (state.items.isEmpty) {
                  return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Belum ada produk',
                      description: 'Tambah produk untuk mulai berjualan.');
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => _cubit.refresh(),
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: state.items.length + (loadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: ZK.primary))),
                        );
                      }
                      final p = state.items[i];
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
                                            ? softBg(ZK.rose, ZK.rose50, dark)
                                            : p.stok <= 10
                                                ? softBg(ZK.amber700, ZK.amber50, dark)
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
