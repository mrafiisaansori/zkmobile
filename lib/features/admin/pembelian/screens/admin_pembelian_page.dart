import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../../shared/widgets/status_tone.dart';
import '../data/pembelian_repository.dart';
import '../widgets/pembelian_detail_sheet.dart';
import 'admin_pembelian_form_page.dart';

// Padanan lib/admin_pembelian_page.dart lama — barang masuk / restok dari
// supplier. Draft bisa diedit/dihapus/diselesaikan; setelah Selesai stok &
// harga beli sudah terkunci (dokumen read-only, aksi cuma "Lihat").
class AdminPembelianPage extends StatefulWidget {
  const AdminPembelianPage({super.key});
  @override
  State<AdminPembelianPage> createState() => _AdminPembelianPageState();
}

class _AdminPembelianPageState extends State<AdminPembelianPage> {
  final _repo = PembelianRepository();
  late final _cubit = ListCubit<Pembelian>(fetchPage: _fetchPage)..load();
  final _search = TextEditingController();
  Timer? _debounce;
  // Filter status tab — dibaca oleh _fetchPage (closure atas field ini),
  // karena ListCubit<T> generik tak punya slot filter tambahan selain
  // search/page.
  String? _status;

  static const _tabs = [
    (null, 'Semua'),
    ('0', 'Draft'),
    ('1', 'Selesai'),
    ('2', 'Dibatalkan'),
  ];

  Future<List<Pembelian>> _fetchPage({String? search, int page = 1}) => _repo.fetchPage(
      search: search, page: page, status: _status == null ? null : int.parse(_status!));

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _cubit.load(search: v));
  }

  Future<void> _tambah() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AdminPembelianFormPage()));
    if (ok == true) _cubit.load(search: _search.text);
  }

  Future<void> _ubah(Pembelian p) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AdminPembelianFormPage(pembelian: p)));
    if (ok == true) _cubit.load(search: _search.text);
  }

  Future<void> _lihat(Pembelian p) async {
    try {
      final full = await _repo.detail(p.id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PembelianDetailSheet(pembelian: full),
      );
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _selesaikan(Pembelian p) async {
    final ok = await confirmDialog(context,
        title: 'Selesaikan pembelian?',
        message:
            'Selesaikan "${p.noNota}"? Stok akan ditambah & harga beli diperbarui. Dokumen akan terkunci.');
    if (!ok) return;
    try {
      await _repo.selesaikan(p.id);
      if (mounted) toastOk(context, 'Pembelian selesai, stok diperbarui');
      _cubit.load(search: _search.text);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Pembelian p) async {
    final ok = await confirmDialog(context,
        title: 'Hapus draft?', message: 'Hapus draft "${p.noNota}"?', danger: true);
    if (!ok) return;
    try {
      await _repo.delete(p);
      if (mounted) toastOk(context, 'Pembelian dihapus');
      _cubit.load(search: _search.text);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    return BlocProvider.value(
      value: _cubit,
      child: SafeArea(
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
                          hintText: 'Cari nomor nota...',
                          hintStyle: TextStyle(color: dark ? Colors.white60 : ZK.slate500, fontSize: 14),
                          prefixIcon:
                              Icon(Icons.search, size: 20, color: dark ? Colors.white60 : ZK.slate400),
                          filled: true,
                          fillColor: dark ? ZK.cardDark : Colors.white,
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: r12,
                              borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
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
                      label: const Text('Buat'),
                      style: FilledButton.styleFrom(
                          backgroundColor: ZK.primary,
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final t in _tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _status = t.$1);
                          _cubit.load(search: _search.text);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _status == t.$1 ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _status == t.$1 ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
                          ),
                          child: Text(t.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _status == t.$1
                                      ? Colors.white
                                      : (dark ? Colors.white70 : ZK.slate500))),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<ListCubit<Pembelian>, ListState<Pembelian>>(
                builder: (context, state) {
                  final loading = state.status == ListStatus.loading;
                  final data = state.items;
                  if (loading) {
                    return const Center(child: CircularProgressIndicator(color: ZK.primary));
                  }
                  // Gagal muat beda dengan kosong: tampilkan sebab + muat ulang.
                  if (state.status == ListStatus.error && data.isEmpty) {
                    return RError(
                        message: state.error ?? 'Periksa koneksi internet lalu muat ulang.',
                        onRetry: () => _cubit.refresh());
                  }
                  if (data.isEmpty) {
                    return const EmptyState(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Belum ada pembelian',
                        description: 'Catat barang masuk dari supplier di sini.');
                  }
                  return RefreshIndicator(
                    color: ZK.primary,
                    onRefresh: () => _cubit.load(search: _search.text),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: data.length,
                      itemBuilder: (_, i) {
                        final p = data[i];
                        final (bg, tone) = statusTone(p.status, dark);
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
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                    color: dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.shopping_cart_outlined,
                                    color: ZK.primary, size: 24),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.noNota,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                    const SizedBox(height: 2),
                                    Text(
                                        [
                                          if (p.tanggal != null) p.tanggal!,
                                          p.namaSupplier ?? 'Tanpa supplier',
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: muted)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: bg, borderRadius: BorderRadius.circular(6)),
                                      child: Text(statusLabel[p.status] ?? '-',
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w700, color: tone)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _lihat(p),
                                      tooltip: 'Lihat',
                                      icon: Icon(Icons.visibility_outlined,
                                          size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                  if (p.status == 0) ...[
                                    IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _ubah(p),
                                        tooltip: 'Ubah',
                                        icon: Icon(Icons.edit_outlined,
                                            size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                    IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _selesaikan(p),
                                        tooltip: 'Selesaikan',
                                        icon: Icon(Icons.check_circle_outline, size: 18, color: okTone(dark))),
                                    IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _hapus(p),
                                        tooltip: 'Hapus',
                                        icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                                  ],
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
      ),
    );
  }
}
