import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../data/stok_repository.dart';
import '../widgets/stok_adjust_sheet.dart';

// Padanan lib/admin_stok_page.dart lama — penyesuaian stok masuk/keluar per
// produk.
class AdminStokPage extends StatelessWidget {
  const AdminStokPage({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = StokRepository();
    return BlocProvider(
      create: (_) => ListCubit<Produk>(fetchPage: repo.fetchPage, pageSize: StokRepository.pageSize)
        ..load(),
      child: const _AdminStokView(),
    );
  }
}

class _AdminStokView extends StatefulWidget {
  const _AdminStokView();
  @override
  State<_AdminStokView> createState() => _AdminStokViewState();
}

class _AdminStokViewState extends State<_AdminStokView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        context.read<ListCubit<Produk>>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => context.read<ListCubit<Produk>>().load(search: v));
  }

  Future<void> _sesuaikan(Produk p) async {
    final ok = await showStokAdjustSheet(context, p);
    if (ok == true && mounted) context.read<ListCubit<Produk>>().refresh();
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
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _search,
                onChanged: _onSearch,
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                decoration: InputDecoration(
                  hintText: 'Cari produk untuk penyesuaian stok...',
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
          Expanded(
            child: BlocBuilder<ListCubit<Produk>, ListState<Produk>>(
              builder: (context, state) {
                final loading = state.status == ListStatus.loading;
                final loadingMore = state.status == ListStatus.loadingMore;
                final data = state.items;
                if (loading) {
                  return const Center(child: CircularProgressIndicator(color: ZK.primary));
                }
                // Gagal muat beda dengan kosong: tampilkan sebab + muat ulang.
                if (state.status == ListStatus.error && data.isEmpty) {
                  return RError(
                      message: state.error ?? 'Periksa koneksi internet lalu muat ulang.',
                      onRetry: () => context.read<ListCubit<Produk>>().refresh());
                }
                if (data.isEmpty) {
                  return const EmptyState(
                      icon: Icons.inventory_outlined,
                      title: 'Produk tidak ditemukan',
                      description: 'Coba kata kunci lain.');
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => context.read<ListCubit<Produk>>().refresh(),
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: data.length + (loadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= data.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: ZK.primary))),
                        );
                      }
                      final p = data[i];
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
                                  Text(rupiah(p.hargaJual), style: TextStyle(fontSize: 12, color: muted)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: p.stok <= 0
                                            ? softBg(ZK.rose, ZK.rose50, dark)
                                            : p.stok <= 10
                                                ? softBg(ZK.amber700, ZK.amber50, dark)
                                                : (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text('Stok ${p.stok}',
                                        style: TextStyle(
                                            fontSize: 11,
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
                            IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _sesuaikan(p),
                                tooltip: 'Sesuaikan stok',
                                icon: Icon(Icons.swap_vert,
                                    size: 20, color: dark ? Colors.white60 : ZK.slate500)),
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
