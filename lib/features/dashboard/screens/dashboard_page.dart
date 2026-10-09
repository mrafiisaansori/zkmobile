import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/widgets/report_kit.dart';
import '../../../shared/widgets/widgets.dart';
import '../../pos/widgets/buka_sesi_sheet.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/dashboard_cubit.dart';

// Padanan src/app/kasir/dashboard/page.tsx. Isinya hal yang dipakai kasir:
// status sesi kas, penjualan hari ini (satu angka fokus), tombol mulai
// transaksi, dan transaksi terakhir. Tanpa banner promosi.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => DashboardCubit()..load(),
        child: const _DashboardView(),
      );
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  Future<void> _bukaSesi(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BukaSesiSheet(),
    );
    if (ok == true && context.mounted) context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return BlocConsumer<DashboardCubit, DashboardState>(
      listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
      listener: (context, state) => toastError(context, state.error!),
      builder: (context, state) => HeroShell(
        child: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            color: ZK.primary,
            onRefresh: () => context.read<DashboardCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Text(MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted)),
                const SizedBox(height: 10),
                if (!state.shiftActive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShiftBanner(onBuka: () => _bukaSesi(context)),
                  ),
                RHero(
                  label: 'Penjualan hari ini',
                  value: state.loading ? '...' : rupiah(state.total),
                  facts: [
                    ('Transaksi', state.loading ? '...' : '${state.jumlah}'),
                    ('Rata-rata', state.loading || state.jumlah == 0 ? '-' : rupiah(state.total ~/ state.jumlah)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.read<ShellCubit>().goTo(1),
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    label: const Text('Mulai Transaksi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary,
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                  ),
                ),
                const SizedBox(height: 18),
                RSection(
                  title: 'Transaksi terakhir',
                  trailing: TextButton(
                    onPressed: () => context.read<ShellCubit>().goTo(4),
                    child: const Text('Lihat semua', style: TextStyle(fontSize: 13, color: ZK.primary)),
                  ),
                  child: state.loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(color: ZK.primary)),
                        )
                      : state.data.isEmpty
                          ? const RNote('Belum ada transaksi hari ini. Mulai dari tab Kasir.')
                          : RLedger([
                              for (final p in state.data)
                                RLine(p.label, rupiah(p.total),
                                    sub: [
                                      if ((p.jam ?? '').length >= 5) p.jam!.substring(0, 5),
                                      if (p.jenisBayar != null) p.jenisBayar!,
                                    ].join(' · ')),
                            ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
