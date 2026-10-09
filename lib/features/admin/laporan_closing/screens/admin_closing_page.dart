import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/report_kit.dart';
import '../cubit/laporan_closing_cubit.dart';
import '../data/laporan_closing_repository.dart';

// Padanan src/app/admin/laporan/closing/page.tsx — rekap sesi kas SELURUH
// kasir per hari. Fokus halaman: apakah uang di laci cocok (selisih kas),
// lalu rumus per sesi: modal + tunai = seharusnya, dibanding uang dihitung.
class AdminClosingPage extends StatelessWidget {
  const AdminClosingPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => LaporanClosingCubit(LaporanClosingRepository()),
        child: const _AdminClosingView(),
      );
}

class _AdminClosingView extends StatelessWidget {
  const _AdminClosingView();

  String _fmtJam(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return '-';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _selisihText(int? v) {
    if (v == null) return 'Belum dihitung';
    if (v == 0) return 'Pas';
    return v < 0 ? 'Kurang ${rupiah(-v)}' : 'Lebih ${rupiah(v)}';
  }

  Color? _selisihColor(int? v) {
    if (v == null) return null;
    if (v == 0) return okGreen;
    return v < 0 ? ZK.rose : ZK.amber700;
  }

  Future<void> _pickTanggal(BuildContext context, DateTime current) async {
    final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDate: current,
        locale: const Locale('id'));
    if (d == null || !context.mounted) return;
    context.read<LaporanClosingCubit>().setTanggal(d);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LaporanClosingCubit, LaporanClosingState>(
      listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
      listener: (context, state) => toastError(context, state.error!),
      builder: (context, state) {
        final r = state.report;
        return SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: RDateButton(
                    label: dateLabel(context, state.tanggal), onTap: () => _pickTanggal(context, state.tanggal)),
              ),
              Expanded(
                child: state.loading
                    ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                    : r == null && state.error != null
                        ? RError(message: state.error!, onRetry: () => context.read<LaporanClosingCubit>().load())
                        : RefreshIndicator(
                            color: ZK.primary,
                            onRefresh: () => context.read<LaporanClosingCubit>().load(),
                            child: _body(context, r),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, DailyReport? r) {
    final shifts = r?.shift ?? const <DailyReportRow>[];
    final tablet = isTablet(context);
    final selisih = r?.totalSelisihCash ?? 0;
    final hero = RHero(
      label: 'Selisih kas semua sesi',
      value: shifts.isEmpty ? '-' : _selisihText(selisih),
      valueColor: shifts.isEmpty ? null : _selisihColor(selisih),
      facts: [
        ('Tunai', rupiah(r?.totalCashSales ?? 0)),
        ('Non-tunai', rupiah(r?.totalNonCashSales ?? 0)),
        ('Omzet', rupiah(r?.totalOmzet ?? 0)),
      ],
      footnote: 'Uang seharusnya = modal awal + penjualan tunai. Selisih = uang dihitung − uang seharusnya.',
    );
    final cards = [for (final s in shifts) _shiftCard(context, s)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        hero,
        const SizedBox(height: 18),
        Text(shifts.isEmpty ? 'Sesi kasir' : '${shifts.length} sesi kasir',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RColors.of(context).fg)),
        const SizedBox(height: 10),
        if (shifts.isEmpty)
          const RCard(child: RNote('Tidak ada kasir yang membuka sesi kas pada tanggal ini.'))
        else if (tablet)
          LayoutBuilder(
            builder: (context, cons) => Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [for (final w in cards) SizedBox(width: (cons.maxWidth - 14) / 2, child: w)],
            ),
          )
        else
          for (final w in cards) Padding(padding: const EdgeInsets.only(bottom: 14), child: w),
      ],
    );
  }

  Widget _shiftCard(BuildContext context, DailyReportRow s) {
    final c = RColors.of(context);
    final buka = s.status == 'OPEN';
    return RCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.kasir ?? '-', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.fg)),
                    const SizedBox(height: 2),
                    Text('${s.station ?? 'Tanpa laci'} · ${_fmtJam(s.bukaAt)}–${buka ? 'sekarang' : _fmtJam(s.tutupAt)}',
                        style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              RTag(buka ? 'Masih buka' : 'Ditutup', buka ? ZK.amber700 : c.muted),
            ],
          ),
          const SizedBox(height: 8),
          RLedger([
            RLine('Modal awal', rupiah(s.modalAwal)),
            RLine('Penjualan tunai', '+ ${rupiah(s.cashSales)}'),
            RLine('Uang seharusnya', rupiah(s.expectedCash), strong: true),
            RLine('Uang dihitung', s.actualCash == null ? 'Belum dihitung' : rupiah(s.actualCash!)),
            RLine('Selisih', _selisihText(s.selisihCash), valueColor: _selisihColor(s.selisihCash)),
            if (s.nonCashSales > 0) RLine('Non-tunai (di luar laci)', rupiah(s.nonCashSales)),
          ]),
        ],
      ),
    );
  }
}
