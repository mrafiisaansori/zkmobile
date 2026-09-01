import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../cubit/keuangan_cubit.dart';

// Padanan src/app/admin/laporan/page.tsx (FinanceDashboard) — omzet/laba/PPN
// per periode + rekap lengkap (PRO/BUSINESS). Tabel transaksi mentah sengaja
// tidak diulang di sini (sudah ada di menu Laporan Transaksi); export
// Excel/PDF juga dilewati (fitur sekunder, web-only untuk saat ini).
class AdminKeuanganPage extends StatelessWidget {
  const AdminKeuanganPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => KeuanganCubit(),
        child: const _AdminKeuanganView(),
      );
}

class _AdminKeuanganView extends StatefulWidget {
  const _AdminKeuanganView();
  @override
  State<_AdminKeuanganView> createState() => _AdminKeuanganViewState();
}

class _AdminKeuanganViewState extends State<_AdminKeuanganView> {
  String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _pickRange(BuildContext context, DateTimeRange current) async {
    final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: current,
        locale: const Locale('id'));
    if (r == null) return;
    if (!context.mounted) return;
    context.read<KeuanganCubit>().setRange(r);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate500;
    return BlocBuilder<KeuanganCubit, KeuanganState>(
      builder: (context, s) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: OutlinedButton.icon(
                  onPressed: () => _pickRange(context, s.range),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text('${_iso(s.range.start)} → ${_iso(s.range.end)}',
                      style: const TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: dark ? ZK.cardDark : Colors.white,
                    foregroundColor: dark ? Colors.white : ZK.primary,
                    side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    minimumSize: const Size(double.infinity, 46),
                    shape: const RoundedRectangleBorder(borderRadius: r12),
                  ),
                ),
              ),
              Expanded(
                child: s.status == KeuanganStatus.loading
                    ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                    : (s.status == KeuanganStatus.error || s.penjualan == null || s.pendapatan == null)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(s.error ?? 'Gagal memuat laporan',
                                      textAlign: TextAlign.center, style: TextStyle(color: fg)),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                      onPressed: () => context.read<KeuanganCubit>().load(),
                                      child: const Text('Coba lagi')),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: ZK.primary,
                            onRefresh: () => context.read<KeuanganCubit>().load(),
                            child: Builder(builder: (context) {
                              final penjualan = s.penjualan!;
                              final pendapatan = s.pendapatan!;
                              final rekap = s.rekap;
                              final tablet = isTablet(context);
                              // Tablet: Row of Expanded (tinggi ikut konten), bukan
                              // GridView beraspek-rasio tetap — di layar lebar itu
                              // bikin sel jauh lebih tinggi dari kontennya.
                              final statRow = tablet
                                  ? IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(child: _statCard('Omzet (bersih, tanpa PPN)', rupiah(penjualan.omzet),
                                              Icons.account_balance_wallet_outlined, const Color(0xFF047857), dark)),
                                          const SizedBox(width: 10),
                                          Expanded(child: _statCard('Jumlah transaksi', '${penjualan.jumlahTransaksi}',
                                              Icons.receipt_long_outlined, ZK.primary, dark)),
                                          const SizedBox(width: 10),
                                          Expanded(child: _statCard('PPN terkumpul', rupiah(penjualan.totalPpn),
                                              Icons.receipt_outlined, ZK.amber700, dark)),
                                          const SizedBox(width: 10),
                                          Expanded(child: _statCard('Laba kotor', rupiah(pendapatan.laba), Icons.trending_up,
                                              const Color(0xFF047857), dark)),
                                        ],
                                      ),
                                    )
                                  : GridView.count(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.6,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: [
                                        _statCard('Omzet (bersih, tanpa PPN)', rupiah(penjualan.omzet),
                                            Icons.account_balance_wallet_outlined, const Color(0xFF047857), dark),
                                        _statCard('Jumlah transaksi', '${penjualan.jumlahTransaksi}',
                                            Icons.receipt_long_outlined, ZK.primary, dark),
                                        _statCard('PPN terkumpul', rupiah(penjualan.totalPpn),
                                            Icons.receipt_outlined, ZK.amber700, dark),
                                        _statCard('Laba kotor', rupiah(pendapatan.laba), Icons.trending_up,
                                            const Color(0xFF047857), dark),
                                      ],
                                    );
                              final supportRow = tablet
                                  ? Row(
                                      children: [
                                        Expanded(child: _supportStat('Modal (HPP)', rupiah(pendapatan.modal), fg, muted)),
                                        Expanded(child: _supportStat(
                                            'Service charge', rupiah(penjualan.totalService), fg, muted)),
                                        Expanded(child: _supportStat('PPN (titipan pajak)', rupiah(penjualan.totalPpn), fg, muted)),
                                        Expanded(child: _supportStat(
                                            'Total diterima (bruto)', rupiah(penjualan.totalDibayar), fg, muted)),
                                      ],
                                    )
                                  : GridView.count(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 2.4,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: [
                                        _supportStat('Modal (HPP)', rupiah(pendapatan.modal), fg, muted),
                                        _supportStat(
                                            'Service charge', rupiah(penjualan.totalService), fg, muted),
                                        _supportStat('PPN (titipan pajak)', rupiah(penjualan.totalPpn), fg, muted),
                                        _supportStat(
                                            'Total diterima (bruto)', rupiah(penjualan.totalDibayar), fg, muted),
                                      ],
                                    );
                              return ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                children: [
                                  statRow,
                                  const SizedBox(height: 14),
                                  _card(dark, child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        supportRow,
                                        const SizedBox(height: 8),
                                        Text(
                                            'Omzet = penjualan bersih tanpa PPN & service. PPN bukan pendapatan — disetor ke negara.',
                                            style: TextStyle(fontSize: 11, color: muted)),
                                      ],
                                    ),
                                  )),
                                  const SizedBox(height: 14),
                                  if (rekap == null)
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: ZK.amber50, borderRadius: r14),
                                      child: const Text(
                                          'Rekap laporan lengkap (per metode bayar, per kasir, produk terlaris, stok menipis) tersedia di paket PRO dan BUSINESS.',
                                          style: TextStyle(fontSize: 12.5, color: ZK.amber700)),
                                    )
                                  else ...[
                                    _breakdownCard(
                                        dark,
                                        fg,
                                        'Penjualan per metode pembayaran',
                                        rekap.perMetodeBayar
                                            .map((m) => (
                                                  '${m.metode} (${m.jumlahTransaksi}x)',
                                                  rupiah(m.total)
                                                ))
                                            .toList()),
                                    const SizedBox(height: 14),
                                    _breakdownCard(
                                        dark,
                                        fg,
                                        'Rekap penjualan per kasir',
                                        rekap.perKasir
                                            .map((k) => (
                                                  '${k.kasir} (${k.jumlahTransaksi}x)',
                                                  rupiah(k.total)
                                                ))
                                            .toList()),
                                    const SizedBox(height: 14),
                                    _breakdownCard(
                                        dark,
                                        fg,
                                        'Produk terlaris',
                                        rekap.produkTerlaris
                                            .map((p) => ('${p.nama} (${p.qty})', rupiah(p.omzet)))
                                            .toList()),
                                    const SizedBox(height: 14),
                                    _breakdownCard(
                                        dark,
                                        fg,
                                        'Produk stok menipis',
                                        rekap.produkStokMenipis
                                            .map((p) => (p.nama, 'sisa ${p.stok}'))
                                            .toList(),
                                        valueColor: ZK.rose),
                                  ],
                                ],
                              );
                            }),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(bool dark, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: child,
      );

  Widget _statCard(String label, String value, IconData icon, Color tone, bool dark) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: tone),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: dark ? Colors.white60 : ZK.slate500)),
          ],
        ),
      );

  Widget _supportStat(String label, String value, Color fg, Color muted) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: muted)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
        ],
      );

  Widget _breakdownCard(bool dark, Color fg, String title, List<(String, String)> rows,
          {Color? valueColor}) =>
      _card(dark, child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Tidak ada data.',
                    style: TextStyle(fontSize: 12.5, color: dark ? Colors.white54 : ZK.slate400)),
              )
            else
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(r.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: dark ? Colors.white70 : ZK.slate600)),
                      ),
                      const SizedBox(width: 8),
                      Text(r.$2,
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor ?? fg)),
                    ],
                  ),
                ),
          ],
        ),
      ));
}
