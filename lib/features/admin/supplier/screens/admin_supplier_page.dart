import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../data/supplier_repository.dart';
import '../widgets/supplier_form_sheet.dart';

// Padanan src/app/admin/supplier/page.tsx — CRUD supplier.
// Versi BLoC dari admin_supplier_page.dart lama.
class AdminSupplierPage extends StatefulWidget {
  const AdminSupplierPage({super.key});
  @override
  State<AdminSupplierPage> createState() => _AdminSupplierPageState();
}

class _AdminSupplierPageState extends State<AdminSupplierPage> {
  final _repo = SupplierRepository();
  final _search = TextEditingController();
  Timer? _debounce;
  late final ListCubit<Supplier> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ListCubit<Supplier>(fetchPage: _repo.fetchPage, deleteItem: _repo.delete)..load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _cubit.load(search: _search.text));
  }

  Future<void> _openForm({Supplier? item}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupplierFormSheet(initial: item),
    );
    if (result == null) return;
    final formCubit = FormSubmitCubit<Supplier>();
    final saved = await formCubit.submit(
        () => item == null ? _repo.create(result) : _repo.update(item.id, result));
    final error = formCubit.state.error;
    formCubit.close();
    if (!mounted) return;
    if (saved != null) {
      toastOk(context, item == null ? 'Supplier ditambahkan' : 'Supplier diperbarui');
      _cubit.refresh();
    } else if (error != null) {
      toastError(context, error);
    }
  }

  Future<void> _hapus(Supplier item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus supplier?', message: 'Hapus supplier "${item.nama}"?', danger: true);
    if (!ok) return;
    final success = await _cubit.remove(item);
    if (!mounted) return;
    if (success) {
      toastOk(context, 'Supplier dihapus');
    } else {
      final err = _cubit.state.error;
      if (err != null) toastError(context, err);
    }
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
                        hintText: 'Cari nama / telepon...',
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
                    onPressed: () => _openForm(),
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
            child: BlocBuilder<ListCubit<Supplier>, ListState<Supplier>>(
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
                      icon: Icons.local_shipping_outlined,
                      title: 'Belum ada supplier',
                      description: 'Tambah data supplier untuk pembelian barang.');
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => _cubit.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final s = state.items[i];
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
                              child: const Icon(Icons.local_shipping_outlined,
                                  color: ZK.primary, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.nama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                  const SizedBox(height: 2),
                                  if (s.noTelp != null || s.email != null || s.alamat != null)
                                    Text(
                                        [
                                          if (s.noTelp != null) s.noTelp!,
                                          if (s.email != null) s.email!,
                                          if (s.alamat != null) s.alamat!,
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: muted)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: s.status == 0
                                            ? softBg(ZK.rose, ZK.rose50, dark)
                                            : (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(s.status == 0 ? 'Nonaktif' : 'Aktif',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: s.status == 0
                                                ? ZK.rose
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
                                    onPressed: () => _openForm(item: s),
                                    icon: Icon(Icons.edit_outlined,
                                        size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _hapus(s),
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
