import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../data/voucher_repository.dart';
import '../widgets/voucher_form_sheet.dart';

// Padanan lib/admin_voucher_page.dart lama — CRUD voucher/promo. Voucher
// yang SUDAH ADA tetap bisa dikelola di semua plan; bikin voucher BARU
// PRO-only.
class AdminVoucherPage extends StatelessWidget {
  const AdminVoucherPage({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = VoucherRepository();
    return BlocProvider(
      create: (_) => ListCubit<Voucher>(fetchPage: repo.fetchPage, deleteItem: repo.delete)..load(),
      child: const _AdminVoucherView(),
    );
  }
}

class _AdminVoucherView extends StatelessWidget {
  const _AdminVoucherView();

  Future<void> _openForm(BuildContext context, {Voucher? item}) async {
    if (item == null && !Session.isPro) {
      toastError(context, 'Bikin voucher baru hanya tersedia untuk paket PRO/BUSINESS.');
      return;
    }
    final ok = await showVoucherFormSheet(context, initial: item);
    if (ok == true && context.mounted) context.read<ListCubit<Voucher>>().refresh();
  }

  Future<void> _hapus(BuildContext context, Voucher item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus voucher?', message: 'Hapus voucher "${item.kode}"?', danger: true);
    if (!ok) return;
    final cubit = context.read<ListCubit<Voucher>>();
    final removed = await cubit.remove(item);
    if (!context.mounted) return;
    if (removed) {
      toastOk(context, 'Voucher dihapus');
    } else if (cubit.state.error != null) {
      toastError(context, cubit.state.error!);
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
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Voucher'),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
          if (!Session.isPro)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: softBg(ZK.amber700, ZK.amber50, dark), borderRadius: r12),
                child: Text('Bikin voucher baru tersedia mulai paket PRO. Voucher lama tetap bisa dikelola.',
                    style: TextStyle(fontSize: 12, color: ZK.amber700)),
              ),
            ),
          Expanded(
            child: BlocBuilder<ListCubit<Voucher>, ListState<Voucher>>(
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
                      onRetry: () => context.read<ListCubit<Voucher>>().refresh());
                }
                if (data.isEmpty) {
                  return const EmptyState(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Belum ada voucher',
                      description: 'Buat kode promo untuk dipakai kasir saat checkout.');
                }
                return RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: () => context.read<ListCubit<Voucher>>().refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final v = data[i];
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
                              child: const Icon(Icons.confirmation_number_outlined,
                                  color: ZK.primary, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.kode,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          color: fg)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${v.persen ? '${v.nilai}%' : rupiah(v.nilai)} · Min. ${rupiah(v.minTransaksi)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: muted)),
                                  Text('Berlaku ${v.validFrom ?? '-'} s/d ${v.validUntil ?? '-'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: muted)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: v.aktif
                                            ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50)
                                            : softBg(ZK.rose, ZK.rose50, dark),
                                        borderRadius: BorderRadius.circular(999)),
                                    child: Text(v.aktif ? 'Aktif' : 'Nonaktif',
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: v.aktif
                                                ? (dark ? Colors.white : ZK.brand700)
                                                : ZK.rose)),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _openForm(context, item: v),
                                    icon: Icon(Icons.edit_outlined,
                                        size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _hapus(context, v),
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
