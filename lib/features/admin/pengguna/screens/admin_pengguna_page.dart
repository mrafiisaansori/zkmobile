import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../data/pengguna_repository.dart';
import '../widgets/pengguna_form_sheet.dart';

// Padanan src/app/admin/user/page.tsx — manajemen akun kasir & gudang.
// Level 1=Admin (tidak dikelola di sini), 2=Kasir, 3=Gudang.
// Versi BLoC dari admin_pengguna_page.dart lama.
class AdminPenggunaPage extends StatefulWidget {
  const AdminPenggunaPage({super.key});
  @override
  State<AdminPenggunaPage> createState() => _AdminPenggunaPageState();
}

class _AdminPenggunaPageState extends State<AdminPenggunaPage> {
  final _repo = PenggunaRepository();
  late final ListCubit<Pengguna> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ListCubit<Pengguna>(fetchPage: _repo.fetchPage, deleteItem: _repo.delete)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openForm({Pengguna? item}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PenggunaFormSheet(initial: item),
    );
    if (result == null) return;
    final formCubit = FormSubmitCubit<Pengguna>();
    final saved = await formCubit.submit(
        () => item == null ? _repo.create(result) : _repo.update(item.id, result));
    final error = formCubit.state.error;
    formCubit.close();
    if (!mounted) return;
    if (saved != null) {
      toastOk(context, item == null ? 'Pengguna ditambahkan' : 'Pengguna diperbarui');
      _cubit.refresh();
    } else if (error != null) {
      toastError(context, error);
    }
  }

  Future<void> _hapus(Pengguna item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus pengguna?', message: 'Hapus akun "${item.nama}"?', danger: true);
    if (!ok) return;
    final success = await _cubit.remove(item);
    if (!mounted) return;
    if (success) {
      toastOk(context, 'Pengguna dihapus');
    } else {
      final err = _cubit.state.error;
      if (err != null) toastError(context, err);
    }
  }

  Future<void> _resetPassword(Pengguna item) async {
    final ok = await confirmDialog(context,
        title: 'Reset password?',
        message:
            'Buat password baru acak untuk "${item.nama}"? Password lama tidak bisa dipakai lagi setelah ini.');
    if (!ok) return;
    try {
      final res = await _repo.resetPassword(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: r14),
          title: const Text('Password baru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Password baru untuk akun ${res['username']}. Catat sekarang, hanya tampil sekali.',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              SelectableText('${res['password']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
            ],
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(c),
                style: FilledButton.styleFrom(backgroundColor: ZK.primary),
                child: const Text('Selesai')),
          ],
        ),
      );
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
                label: const Text('Tambah Pengguna'),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ListCubit<Pengguna>, ListState<Pengguna>>(
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
                      icon: Icons.manage_accounts_outlined,
                      title: 'Belum ada pengguna',
                      description: 'Tambah akun kasir.');
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => _cubit.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final p = state.items[i];
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
                              child: const Icon(Icons.manage_accounts_outlined,
                                  color: ZK.primary, size: 24),
                            ),
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
                                  Text('${p.username} · ${p.roleLabel}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: muted)),
                                ],
                              ),
                            ),
                            if (p.level != 1)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _resetPassword(p),
                                      tooltip: 'Reset password',
                                      icon: Icon(Icons.key_outlined,
                                          size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                  IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _openForm(item: p),
                                      icon: Icon(Icons.edit_outlined,
                                          size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                  IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _hapus(p),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: ZK.rose)),
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
