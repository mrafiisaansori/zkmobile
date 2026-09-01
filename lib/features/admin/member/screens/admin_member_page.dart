import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../widgets/member_form_sheet.dart';

// Padanan src/app/admin/member/page.tsx — CRUD member/pelanggan. Fitur PRO:
// FREE cuma dapat pesan upgrade, sama seperti _requirePro di pos_page.dart.
// Versi BLoC dari admin_member_page.dart lama.
class AdminMemberPage extends StatefulWidget {
  const AdminMemberPage({super.key});
  @override
  State<AdminMemberPage> createState() => _AdminMemberPageState();
}

class _AdminMemberPageState extends State<AdminMemberPage> {
  final _repo = MemberRepository();
  final _search = TextEditingController();
  Timer? _debounce;
  late final ListCubit<Member> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ListCubit<Member>(fetchPage: _repo.fetchPage, deleteItem: _repo.delete);
    if (Session.isPro) _cubit.load();
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

  Future<void> _openForm({Member? item}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberFormSheet(initial: item),
    );
    if (result == null) return;
    final formCubit = FormSubmitCubit<Member>();
    final saved = await formCubit.submit(
        () => item == null ? _repo.create(result) : _repo.update(item.id, result));
    final error = formCubit.state.error;
    formCubit.close();
    if (!mounted) return;
    if (saved != null) {
      toastOk(context, item == null ? 'Member ditambahkan' : 'Member diperbarui');
      _cubit.refresh();
    } else if (error != null) {
      toastError(context, error);
    }
  }

  Future<void> _hapus(Member item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus member?', message: 'Hapus member "${item.nama}"?', danger: true);
    if (!ok) return;
    final success = await _cubit.remove(item);
    if (!mounted) return;
    if (success) {
      toastOk(context, 'Member dihapus');
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
                Text('Fitur Member tersedia mulai paket PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 8),
                Text(
                    'Kelola data pelanggan, riwayat transaksi, dan pilih member langsung dari halaman kasir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: muted)),
              ],
            ),
          ),
        ),
      );
    }

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
                        hintText: 'Cari nama / no. HP / kode...',
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
            child: BlocBuilder<ListCubit<Member>, ListState<Member>>(
              bloc: _cubit,
              builder: (context, state) {
                final loading = state.status == ListStatus.initial || state.status == ListStatus.loading;
                if (loading) {
                  return const Center(child: CircularProgressIndicator(color: ZK.primary));
                }
                if (state.items.isEmpty) {
                  return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'Belum ada member',
                      description: 'Tambah data pelanggan tetap Anda.');
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => _cubit.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final m = state.items[i];
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
                              child: const Icon(Icons.people_outline, color: ZK.primary, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.nama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                  const SizedBox(height: 2),
                                  Text([if (m.kode != null) m.kode!, m.noHp].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: muted)),
                                  if (m.status == 0) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: ZK.rose50, borderRadius: BorderRadius.circular(999)),
                                      child: const Text('Nonaktif',
                                          style: TextStyle(
                                              fontSize: 10.5, fontWeight: FontWeight.w700, color: ZK.rose)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _openForm(item: m),
                                    icon: Icon(Icons.edit_outlined,
                                        size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _hapus(m),
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
