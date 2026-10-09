import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../data/kategori_repository.dart';
import '../widgets/kategori_form_sheet.dart';

// Padanan src/app/admin/kategori/page.tsx — CRUD kategori produk.
// Versi BLoC dari admin_kategori_page.dart lama: list dipindah ke
// ListCubit<Kategori>, create/update ke FormSubmitCubit<Kategori>.
class AdminKategoriPage extends StatefulWidget {
  const AdminKategoriPage({super.key});
  @override
  State<AdminKategoriPage> createState() => _AdminKategoriPageState();
}

class _AdminKategoriPageState extends State<AdminKategoriPage> {
  final _repo = KategoriRepository();
  late final ListCubit<Kategori> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ListCubit<Kategori>(fetchPage: _repo.fetchPage, deleteItem: _repo.delete)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openForm({Kategori? item}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KategoriFormSheet(initial: item?.deskripsi),
    );
    if (result == null || result.trim().isEmpty) return;
    final formCubit = FormSubmitCubit<Kategori>();
    final saved = await formCubit.submit(() =>
        item == null ? _repo.create(result.trim()) : _repo.update(item.id, result.trim()));
    final error = formCubit.state.error;
    formCubit.close();
    if (!mounted) return;
    if (saved != null) {
      toastOk(context, item == null ? 'Kategori ditambahkan' : 'Kategori diperbarui');
      _cubit.refresh();
    } else if (error != null) {
      toastError(context, error);
    }
  }

  Future<void> _hapus(Kategori item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus kategori?',
        message: 'Hapus kategori "${item.deskripsi}"?',
        danger: true);
    if (!ok) return;
    final success = await _cubit.remove(item);
    if (!mounted) return;
    if (success) {
      toastOk(context, 'Kategori dihapus');
    } else {
      final err = _cubit.state.error;
      if (err != null) toastError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
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
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Kategori'),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ListCubit<Kategori>, ListState<Kategori>>(
              bloc: _cubit,
              builder: (context, state) {
                final loading = state.status == ListStatus.initial || state.status == ListStatus.loading;
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
                      icon: Icons.sell_outlined,
                      title: 'Belum ada kategori',
                      description: 'Tambah kategori untuk mengelompokkan produk.');
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => _cubit.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final k = state.items[i];
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
                              child: const Icon(Icons.sell_outlined, color: ZK.primary, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(k.deskripsi,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _openForm(item: k),
                                    icon: Icon(Icons.edit_outlined,
                                        size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _hapus(k),
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
