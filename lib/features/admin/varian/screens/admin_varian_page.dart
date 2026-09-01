import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../data/varian_repository.dart';
import '../widgets/group_form_sheet.dart';
import '../widgets/options_sheet.dart';

// Padanan src/app/admin/modifier/page.tsx — grup varian (ukuran, topping,
// dsb) + opsi per grup. Opsi dikelola lewat sheet terpisah, sama seperti web.
class AdminVarianPage extends StatelessWidget {
  const AdminVarianPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = VarianRepository();
    return BlocProvider(
      create: (_) => ListCubit<ModifierGroup>(fetchPage: repo.groups)..load(),
      child: _AdminVarianView(repo: repo),
    );
  }
}

class _AdminVarianView extends StatelessWidget {
  final VarianRepository repo;
  const _AdminVarianView({required this.repo});

  Future<void> _openForm(BuildContext context, {ModifierGroup? item}) async {
    final cubit = context.read<ListCubit<ModifierGroup>>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await repo.create(result['nama'] as String, result['tipe'] as String, result['wajib'] as bool);
        if (context.mounted) toastOk(context, 'Grup ditambahkan');
      } else {
        await repo.update(
            item.id, result['nama'] as String, result['tipe'] as String, result['wajib'] as bool);
        if (context.mounted) toastOk(context, 'Grup diperbarui');
      }
      cubit.refresh();
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> _hapusGroup(BuildContext context, ModifierGroup item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus grup?',
        message: 'Hapus grup "${item.nama}" beserta semua opsinya?',
        danger: true);
    if (!ok) return;
    final cubit = context.read<ListCubit<ModifierGroup>>();
    try {
      await repo.delete(item.id);
      if (context.mounted) toastOk(context, 'Grup dihapus');
      cubit.refresh();
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> _kelolaOpsi(BuildContext context, ModifierGroup item) async {
    final cubit = context.read<ListCubit<ModifierGroup>>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OptionsSheet(group: item, repo: repo, onChanged: cubit.refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    final tablet = isTablet(context);
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
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Grup'),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ListCubit<ModifierGroup>, ListState<ModifierGroup>>(
              builder: (context, state) {
                if (state.status == ListStatus.loading || state.status == ListStatus.initial) {
                  return const Center(child: CircularProgressIndicator(color: ZK.primary));
                }
                if (state.items.isEmpty) {
                  return const EmptyState(
                      icon: Icons.layers_outlined,
                      title: 'Belum ada grup varian',
                      description: "Mis. buat grup 'Ukuran' dengan opsi S, M, L.");
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => context.read<ListCubit<ModifierGroup>>().refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: tablet ? 2 : 1,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: tablet ? 2.4 : 2.6,
                    ),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final g = state.items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dark ? ZK.cardDark : Colors.white,
                          borderRadius: r14,
                          border: Border.all(color: lineColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.layers_outlined, size: 16, color: ZK.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(g.nama,
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                ),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _openForm(context, item: g),
                                    icon: Icon(Icons.edit_outlined,
                                        size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _hapusGroup(context, g),
                                    icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                              ],
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                _badge(g.single ? 'Pilih satu' : 'Pilih banyak',
                                    dark ? ZK.primary.withValues(alpha: 0.18) : ZK.brand50,
                                    dark ? Colors.white : ZK.brand700),
                                if (g.wajib) _badge('Wajib', ZK.amber50, ZK.amber700),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${g.options.length} opsi',
                                style: TextStyle(fontSize: 12, color: muted)),
                            const Spacer(),
                            SizedBox(
                              height: 34,
                              child: OutlinedButton.icon(
                                onPressed: () => _kelolaOpsi(context, g),
                                icon: const Icon(Icons.tune, size: 15),
                                label: const Text('Kelola opsi', style: TextStyle(fontSize: 12.5)),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: ZK.primary,
                                    side: const BorderSide(color: ZK.brand200),
                                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                              ),
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

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
      );
}
