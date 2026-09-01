import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/riwayat_cubit.dart';
import 'riwayat_detail_page.dart';

// Padanan src/app/kasir/riwayat/page.tsx (daftar transaksi kasir).
class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => RiwayatCubit()..load(),
        child: const _RiwayatView(),
      );
}

class _RiwayatView extends StatelessWidget {
  const _RiwayatView();

  String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _pickTanggal(BuildContext context, RiwayatState state) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: state.tanggal,
      locale: const Locale('id'),
    );
    if (d == null || !context.mounted) return;
    context.read<RiwayatCubit>().setTanggal(d);
  }

  Future<void> _pickRange(BuildContext context, RiwayatState state) async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: state.range,
      locale: const Locale('id'),
    );
    if (r == null || !context.mounted) return;
    context.read<RiwayatCubit>().setRange(r);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<RiwayatCubit, RiwayatState>(
        listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
        listener: (context, state) => toastError(context, state.error!),
        builder: (context, state) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final fg = dark ? Colors.white : ZK.slate900;
          final muted = dark ? Colors.white70 : ZK.slate500;
          final lineColor = dark ? ZK.lineDark : ZK.line;
          final summaryBg = dark ? ZK.cardDark : ZK.brand50;
          return HeroShell(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        _modeChip('Tanggal', !state.rangeMode, dark,
                            () => context.read<RiwayatCubit>().setMode(false)),
                        const SizedBox(width: 8),
                        _modeChip('Rentang', state.rangeMode, dark,
                            () => context.read<RiwayatCubit>().setMode(true)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => state.rangeMode
                                ? _pickRange(context, state)
                                : _pickTanggal(context, state),
                            icon: const Icon(Icons.calendar_today_outlined, size: 16),
                            label: Text(
                                state.rangeMode
                                    ? '${_iso(state.range.start)} → ${_iso(state.range.end)}'
                                    : _iso(state.tanggal),
                                style: const TextStyle(fontSize: 12.5)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: dark ? ZK.cardDark : Colors.white,
                              foregroundColor: dark ? Colors.white : ZK.primary,
                              side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: const RoundedRectangleBorder(borderRadius: r12),
                            ),
                          ),
                        ),
                        if (!state.rangeMode && !state.isToday) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => context.read<RiwayatCubit>().resetToToday(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: dark ? Colors.white : ZK.primary,
                                side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                                shape: const RoundedRectangleBorder(borderRadius: r12),
                              ),
                              child: const Text('Hari Ini', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!state.loading && state.data.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: summaryBg, borderRadius: r12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${state.data.length} transaksi',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white : ZK.brand700)),
                            Text(rupiah(state.total),
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w900, color: fg)),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: state.loading
                        ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                        : state.data.isEmpty
                            ? const EmptyState(
                                icon: Icons.history,
                                title: 'Belum ada transaksi',
                                description: 'Coba pilih tanggal lain.')
                            : RefreshIndicator(
                                color: ZK.primary,
                                onRefresh: () => context.read<RiwayatCubit>().load(),
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                  itemCount: state.data.length,
                                  separatorBuilder: (_, __) =>
                                      Divider(height: 1, color: lineColor),
                                  itemBuilder: (_, i) =>
                                      _row(context, state.data[i], fg, muted),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _modeChip(String label, bool active, bool dark, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
              borderRadius: r12,
              border:
                  Border.all(color: active ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
          ),
        ),
      );

  Widget _row(BuildContext context, Penjualan p, Color fg, Color muted) => InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => RiwayatDetailPage(id: p.id))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          p.tanggal ?? '-',
                          if (p.jam != null) p.jam!,
                          if (p.jenisBayar != null) p.jenisBayar!,
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ),
              Text(rupiah(p.total),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
            ],
          ),
        ),
      );
}
