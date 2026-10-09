import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/dates.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../cubit/admin_dashboard_cubit.dart';

// Dashboard admin — data sama dengan src/app/admin/dashboard/page.tsx di web.
// Urutan mengikuti keputusan pemilik: omzet hari ini (fokus), uang diterima,
// stok yang perlu ditindak (naik ke atas bila ada), tren tahunan, rincian.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => AdminDashboardCubit(),
        child: const _AdminDashboardView(),
      );
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state.status == AdminDashboardStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: ZK.primary));
        }
        final s = state.summary;
        if (state.status == AdminDashboardStatus.error || s == null) {
          return RError(
              message: state.error ?? 'Periksa koneksi internet lalu muat ulang.',
              onRetry: () => context.read<AdminDashboardCubit>().load());
        }
        final tablet = isTablet(context);
        const gap = 14.0;
        final tahun = DateTime.now().year;
        final omzetTahun = state.chart.fold<int>(0, (t, e) => t + e.omzet);

        final hero = RHero(
          label: 'Omzet hari ini',
          value: rupiah(s.pendapatanHariIni),
          facts: [
            ('Transaksi', '${s.transaksiHariIni}'),
            ('Laba kotor', rupiah(s.labaHariIni)),
            ('Rata-rata', rupiah(s.rataRataTransaksi)),
          ],
        );

        // Uang yang benar-benar diterima hari ini, disusun sebagai rumus.
        final kasCard = RSection(
          title: 'Uang diterima hari ini',
          caption: 'PPN adalah titipan pajak, bukan pendapatan.',
          child: RLedger([
            RLine('Omzet bersih', rupiah(s.pendapatanHariIni)),
            RLine('PPN terkumpul', '+ ${rupiah(s.ppnHariIni)}'),
            RLine('Service charge', '+ ${rupiah(s.serviceHariIni)}'),
            RLine('Total diterima', rupiah(s.totalDibayarHariIni), strong: true),
          ]),
        );

        final stokCard = RSection(
          title: 'Perlu restock',
          caption: s.stokMenipis.isEmpty ? null : '${s.stokMenipis.length} produk di bawah stok minimum',
          child: s.stokMenipis.isEmpty
              ? const RNote('Semua stok di atas batas minimum.', icon: Icons.check_circle_outline, ok: true)
              : RLedger([
                  for (final p in s.stokMenipis)
                    RLine(p.nama, p.stok <= 0 ? 'Habis' : 'Sisa ${p.stok}',
                        valueColor: p.stok <= 0 ? ZK.rose : ZK.amber700),
                ]),
        );

        final chartCard = RSection(
          title: 'Omzet & laba per bulan, $tahun',
          caption: omzetTahun == 0 ? 'Belum ada penjualan tahun ini.' : 'Total omzet tahun ini ${rupiah(omzetTahun)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _yearChart(state.chart, c, tablet),
              const SizedBox(height: 12),
              Row(children: [
                _legend(ZK.brand200, 'Omzet', c),
                const SizedBox(width: 16),
                _legend(ZK.primary, 'Laba kotor', c),
              ]),
            ],
          ),
        );

        final terlarisCard = RSection(
          title: 'Terlaris bulan ini',
          caption: 'Urut berdasarkan jumlah terjual',
          child: s.produkTerlaris.isEmpty
              ? const RNote('Belum ada penjualan bulan ini.')
              : RLedger([
                  for (var i = 0; i < s.produkTerlaris.length; i++)
                    RLine(s.produkTerlaris[i].nama, '${s.produkTerlaris[i].qty} terjual',
                        sub: rupiah(s.produkTerlaris[i].omzet),
                        leading: SizedBox(
                          width: 18,
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: c.muted, fontFeatures: tabular)),
                        )),
                ]),
        );

        final transaksiCard = RSection(
          title: 'Transaksi terakhir',
          child: s.transaksiTerbaru.isEmpty
              ? const RNote('Belum ada transaksi hari ini.')
              : RLedger([
                  for (final t in s.transaksiTerbaru)
                    RLine(t.label, rupiah(t.total),
                        sub: [
                          if ((t.jam ?? '').length >= 5) t.jam!.substring(0, 5),
                          t.namaKasir ?? '-',
                          if (t.jenisBayar != null) t.jenisBayar!,
                        ].join(' · ')),
                ]),
        );

        Widget pair(Widget a, Widget b, {int flexA = 1}) => tablet
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: flexA, child: a),
                const SizedBox(width: gap),
                Expanded(child: b),
              ])
            : Column(children: [a, const SizedBox(height: gap), b]);

        return SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            color: ZK.primary,
            onRefresh: () => context.read<AdminDashboardCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                Text(MaterialLocalizations.of(context).formatFullDate(DateTime.tryParse(s.tanggal) ?? DateTime.now()),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted)),
                const SizedBox(height: 10),
                pair(hero, kasCard),
                // Stok menipis naik ke atas hanya bila ada yang perlu ditindak.
                if (s.stokMenipis.isNotEmpty) ...[const SizedBox(height: gap), stokCard],
                const SizedBox(height: gap),
                s.stokMenipis.isEmpty ? pair(chartCard, stokCard, flexA: 2) : chartCard,
                const SizedBox(height: gap),
                pair(terlarisCard, transaksiCard),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _legend(Color color, String label, RColors c) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
      ],
    );

// Satu batang per bulan: omzet (muda) dengan laba (tua) di dalamnya — laba
// selalu bagian dari omzet, jadi ditumpuk, bukan dua batang terpisah.
Widget _yearChart(List<ChartBulan> data, RColors c, bool tablet) {
  final byBulan = {for (final e in data) e.bulan: e};
  final maxVal = data.fold<int>(1, (m, e) => e.omzet > m ? e.omzet : m);
  final now = DateTime.now().month;
  final h = tablet ? 120.0 : 140.0;
  return SizedBox(
    height: h + 22,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var m = 1; m <= 12; m++)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: tablet ? 16 : 12,
                  height: ((byBulan[m]?.omzet ?? 0) / maxVal).clamp(0.0, 1.0) * h + 2,
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(color: ZK.brand200, borderRadius: BorderRadius.circular(3)),
                  child: Container(
                    height: ((byBulan[m]?.laba ?? 0) / maxVal).clamp(0.0, 1.0) * h,
                    decoration: BoxDecoration(color: ZK.primary, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(bulanPendek[m - 1],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: m == now ? FontWeight.w800 : FontWeight.w400,
                        color: m == now ? c.fg : c.muted)),
              ],
            ),
          ),
      ],
    ),
  );
}
