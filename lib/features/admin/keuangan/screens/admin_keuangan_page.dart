import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/widgets/report_kit.dart';
import '../cubit/keuangan_cubit.dart';

// Padanan src/app/admin/laporan/page.tsx — laporan laba rugi sederhana per
// periode: omzet (fokus), rumus laba, uang diterima, lalu rekap PRO/BUSINESS.
// Tabel transaksi mentah ada di menu Laporan Transaksi; export Excel/PDF
// tetap web-only.
class AdminKeuanganPage extends StatelessWidget {
  const AdminKeuanganPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => KeuanganCubit(),
        child: const _AdminKeuanganView(),
      );
}

class _AdminKeuanganView extends StatelessWidget {
  const _AdminKeuanganView();

  Future<void> _pickRange(BuildContext context, DateTimeRange current) async {
    final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: current,
        locale: const Locale('id'));
    if (r == null || !context.mounted) return;
    context.read<KeuanganCubit>().setRange(r);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeuanganCubit, KeuanganState>(
      builder: (context, s) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: RDateButton(label: rangeLabel(context, s.range), onTap: () => _pickRange(context, s.range)),
              ),
              Expanded(
                child: s.status == KeuanganStatus.loading
                    ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                    : (s.status == KeuanganStatus.error || s.penjualan == null || s.pendapatan == null)
                        ? RError(
                            message: s.error ?? 'Periksa koneksi internet lalu muat ulang.',
                            onRetry: () => context.read<KeuanganCubit>().load())
                        : RefreshIndicator(
                            color: ZK.primary,
                            onRefresh: () => context.read<KeuanganCubit>().load(),
                            child: _body(context, s),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, KeuanganState s) {
    final penjualan = s.penjualan!;
    final pendapatan = s.pendapatan!;
    final rekap = s.rekap;
    final tablet = isTablet(context);
    const gap = 14.0;
    final margin = penjualan.omzet == 0 ? null : (pendapatan.laba * 100 / penjualan.omzet);

    final hero = RHero(
      label: 'Omzet periode ini',
      value: rupiah(penjualan.omzet),
      facts: [
        ('Transaksi', '${penjualan.jumlahTransaksi}'),
        ('Laba kotor', rupiah(pendapatan.laba)),
        ('Margin', margin == null ? '-' : '${margin.toStringAsFixed(1)}%'),
      ],
    );

    final labaCard = RSection(
      title: 'Dari omzet ke laba',
      caption: 'Laba kotor = omzet bersih dikurangi modal barang terjual.',
      child: RLedger([
        RLine('Omzet bersih', rupiah(penjualan.omzet)),
        RLine('Modal (HPP)', '− ${rupiah(pendapatan.modal)}'),
        RLine('Laba kotor', rupiah(pendapatan.laba),
            strong: true, valueColor: pendapatan.laba < 0 ? ZK.rose : null),
      ]),
    );

    final kasCard = RSection(
      title: 'Uang diterima',
      caption: 'PPN disetor ke negara, bukan pendapatan toko.',
      child: RLedger([
        RLine('Omzet bersih', rupiah(penjualan.omzet)),
        RLine('PPN', '+ ${rupiah(penjualan.totalPpn)}'),
        RLine('Service charge', '+ ${rupiah(penjualan.totalService)}'),
        RLine('Total diterima', rupiah(penjualan.totalDibayar), strong: true),
      ]),
    );

    Widget pair(Widget a, Widget b) => tablet
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: gap),
            Expanded(child: b),
          ])
        : Column(children: [a, const SizedBox(height: gap), b]);

    final List<Widget> rekapWidgets;
    if (rekap == null) {
      rekapWidgets = [
        const RCard(
          child: RNote(
              'Rekap per metode bayar, per kasir, produk terlaris, dan stok menipis tersedia di paket PRO dan BUSINESS.',
              icon: Icons.lock_outline),
        ),
      ];
    } else {
      final metode = RSection(
        title: 'Penjualan per metode bayar',
        child: rekap.perMetodeBayar.isEmpty
            ? const RNote('Belum ada pembayaran di periode ini.')
            : RShareList(
                format: rupiah,
                items: [for (final m in rekap.perMetodeBayar) (m.metode, '${m.jumlahTransaksi} trx', m.total)]),
      );
      final kasir = RSection(
        title: 'Penjualan per kasir',
        child: rekap.perKasir.isEmpty
            ? const RNote('Belum ada penjualan di periode ini.')
            : RShareList(
                format: rupiah,
                items: [for (final k in rekap.perKasir) (k.kasir, '${k.jumlahTransaksi} trx', k.total)]),
      );
      final c = RColors.of(context);
      final terlaris = RSection(
        title: 'Produk terlaris',
        caption: 'Urut berdasarkan jumlah terjual',
        child: rekap.produkTerlaris.isEmpty
            ? const RNote('Belum ada produk terjual di periode ini.')
            : RLedger([
                for (var i = 0; i < rekap.produkTerlaris.length; i++)
                  RLine(rekap.produkTerlaris[i].nama, '${rekap.produkTerlaris[i].qty} terjual',
                      sub: rupiah(rekap.produkTerlaris[i].omzet),
                      leading: SizedBox(
                        width: 18,
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: c.muted, fontFeatures: tabular)),
                      )),
              ]),
      );
      final stok = RSection(
        title: 'Perlu restock',
        child: rekap.produkStokMenipis.isEmpty
            ? const RNote('Semua stok di atas batas minimum.', icon: Icons.check_circle_outline, ok: true)
            : RLedger([
                for (final p in rekap.produkStokMenipis)
                  RLine(p.nama, p.stok <= 0 ? 'Habis' : 'Sisa ${p.stok}',
                      valueColor: p.stok <= 0 ? ZK.rose : ZK.amber700),
              ]),
      );
      rekapWidgets = [
        pair(metode, kasir),
        const SizedBox(height: gap),
        pair(terlaris, stok),
      ];
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        hero,
        const SizedBox(height: gap),
        pair(labaCard, kasCard),
        const SizedBox(height: gap),
        ...rekapWidgets,
      ],
    );
  }
}
