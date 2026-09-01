import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../cubit/admin_dashboard_cubit.dart';

const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String _formatTanggal(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_bulanPanjang[d.month - 1]} ${d.year}';
}

// Dashboard admin — isinya disamakan persis dengan src/app/admin/dashboard/page.tsx
// di web (FinanceDashboard): 4 stat utama, angka pendukung, grafik omzet &
// laba tahun berjalan, stok menipis, produk terlaris, transaksi terbaru.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate500;
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state.status == AdminDashboardStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: ZK.primary));
        }
        final s = state.summary;
        if (state.status == AdminDashboardStatus.error || s == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error ?? 'Gagal memuat dashboard',
                      textAlign: TextAlign.center, style: TextStyle(color: fg)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: () => context.read<AdminDashboardCubit>().load(),
                      child: const Text('Coba lagi')),
                ],
              ),
            ),
          );
        }
        final tablet = isTablet(context);
        // Tablet: gap & padding kartu sedikit dipadatkan, dan bagian yang di
        // web berdampingan (chart+stok, terlaris+transaksi) juga dibikin
        // sebaris di sini — supaya informasi yang kelihatan pertama kali
        // lebih banyak, bukan cuma numpuk ke bawah seperti ponsel.
        final gap = tablet ? 10.0 : 14.0;
        final pad = tablet ? 12.0 : 14.0;

        // Tablet: Row of Expanded, bukan GridView beraspek-rasio tetap — grid
        // dengan childAspectRatio bikin sel jauh lebih tinggi dari kontennya
        // di layar lebar (itu sumber ruang kosong besar yang dikeluhkan), Row
        // otomatis setinggi konten.
        final statGrid = tablet
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: _statCard('Omzet hari ini (tanpa PPN)', rupiah(s.pendapatanHariIni),
                            Icons.shopping_bag_outlined, ZK.brand700, dark)),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Transaksi hari ini', '${s.transaksiHariIni}',
                        Icons.receipt_long_outlined, ZK.primary, dark)),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Laba kotor hari ini', rupiah(s.labaHariIni),
                        Icons.trending_up, ZK.amber700, dark)),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Stok menipis', '${s.stokMenipis.length}',
                        Icons.warning_amber_outlined, ZK.rose, dark)),
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
                  _statCard('Omzet hari ini (tanpa PPN)', rupiah(s.pendapatanHariIni),
                      Icons.shopping_bag_outlined, ZK.brand700, dark),
                  _statCard('Transaksi hari ini', '${s.transaksiHariIni}',
                      Icons.receipt_long_outlined, ZK.primary, dark),
                  _statCard('Laba kotor hari ini', rupiah(s.labaHariIni),
                      Icons.trending_up, ZK.amber700, dark),
                  _statCard('Stok menipis', '${s.stokMenipis.length}',
                      Icons.warning_amber_outlined, ZK.rose, dark),
                ],
              );

        final supportRow = tablet
            ? Row(
                children: [
                  Expanded(child: _supportStat('Total diterima (bruto)', rupiah(s.totalDibayarHariIni), fg, muted)),
                  Expanded(child: _supportStat('PPN terkumpul', rupiah(s.ppnHariIni), fg, muted)),
                  Expanded(child: _supportStat('Service charge', rupiah(s.serviceHariIni), fg, muted)),
                  Expanded(child: _supportStat('Rata-rata / transaksi', rupiah(s.rataRataTransaksi), fg, muted)),
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
                  _supportStat('Total diterima (bruto)', rupiah(s.totalDibayarHariIni), fg, muted),
                  _supportStat('PPN terkumpul', rupiah(s.ppnHariIni), fg, muted),
                  _supportStat('Service charge', rupiah(s.serviceHariIni), fg, muted),
                  _supportStat('Rata-rata / transaksi', rupiah(s.rataRataTransaksi), fg, muted),
                ],
              );

        final supportCard = _card(dark, child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              supportRow,
              const SizedBox(height: 8),
              Text(
                  'Omzet = penjualan bersih (tanpa PPN & service). PPN adalah titipan pajak, bukan pendapatan.',
                  style: TextStyle(fontSize: 11, color: muted)),
            ],
          ),
        ));

        final chartCard = _card(dark, child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Omzet & Laba ${DateTime.now().year}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 2),
              Text('Performa penjualan bulanan.', style: TextStyle(fontSize: 12, color: muted)),
              SizedBox(height: tablet ? 8 : 14),
              _yearChart(state.chart, dark, fg, muted, tablet),
              const SizedBox(height: 10),
              Row(
                children: [
                  _legend(ZK.primary, 'Omzet', fg),
                  const SizedBox(width: 16),
                  _legend(ZK.amber700, 'Laba', fg),
                ],
              ),
            ],
          ),
        ));

        final stokCard = _card(dark, child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Produk stok menipis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 2),
              Text('Prioritaskan restock sebelum transaksi ramai.',
                  style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 12),
              if (s.stokMenipis.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                      color: dark ? ZK.primary.withValues(alpha: 0.12) : ZK.brand50,
                      borderRadius: r12),
                  child: Text('Semua stok aman',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.greenAccent : const Color(0xFF047857))),
                )
              else
                for (final p in s.stokMenipis) _row(dark,
                    left: p.nama,
                    right: _badge('${p.stok}', p.stok <= 0 ? ZK.rose : ZK.amber700)),
            ],
          ),
        ));

        final terlarisCard = _card(dark, child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.star, size: 16, color: ZK.amber700),
                const SizedBox(width: 6),
                Text('Produk terlaris bulan ini',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
              ]),
              const SizedBox(height: 2),
              Text('5 produk dengan penjualan terbanyak.',
                  style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 12),
              if (s.produkTerlaris.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Belum ada penjualan bulan ini',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: muted)),
                )
              else
                for (var i = 0; i < s.produkTerlaris.length; i++)
                  _row(dark,
                      leading: CircleAvatar(
                          radius: 11,
                          backgroundColor: ZK.brand50,
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800, color: ZK.primary))),
                      left: s.produkTerlaris[i].nama,
                      right: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${s.produkTerlaris[i].qty} terjual',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
                          Text(rupiah(s.produkTerlaris[i].omzet),
                              style: TextStyle(fontSize: 11, color: muted)),
                        ],
                      )),
            ],
          ),
        ));

        final transaksiCard = _card(dark, child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.receipt_long, size: 16, color: ZK.primary),
                const SizedBox(width: 6),
                Text('Transaksi terbaru',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
              ]),
              const SizedBox(height: 2),
              Text('5 transaksi terakhir.', style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 12),
              if (s.transaksiTerbaru.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Belum ada transaksi',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: muted)),
                )
              else
                for (final t in s.transaksiTerbaru)
                  _row(dark,
                      left: t.label,
                      leftSub:
                          '${t.namaKasir ?? '-'} · ${t.tanggal ?? '-'}, ${(t.jam ?? '').length >= 5 ? t.jam!.substring(0, 5) : t.jam ?? ''}',
                      right: Text(rupiah(t.total),
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, color: fg))),
            ],
          ),
        ));

        return SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            color: ZK.primary,
            onRefresh: () => context.read<AdminDashboardCubit>().load(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, tablet ? 16 : 24),
              children: [
                Text('Ringkasan operasional toko',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 2),
                Text(_formatTanggal(s.tanggal), style: TextStyle(fontSize: 12.5, color: muted)),
                SizedBox(height: gap),
                statGrid,
                SizedBox(height: gap),
                supportCard,
                SizedBox(height: gap),
                if (tablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: chartCard),
                      SizedBox(width: gap),
                      Expanded(child: stokCard),
                    ],
                  )
                else ...[
                  chartCard,
                  const SizedBox(height: 14),
                  stokCard,
                ],
                SizedBox(height: gap),
                if (tablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: terlarisCard),
                      SizedBox(width: gap),
                      Expanded(child: transaksiCard),
                    ],
                  )
                else ...[
                  terlarisCard,
                  const SizedBox(height: 14),
                  transaksiCard,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
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
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : ZK.ink)),
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

Widget _legend(Color color, String label, Color fg) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: fg)),
      ],
    );

Widget _badge(String text, Color tone) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: tone.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: tone)),
    );

Widget _row(bool dark, {Widget? leading, required String left, String? leftSub, required Widget right}) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: r12,
        border: Border.all(color: dark ? ZK.lineDark : ZK.line),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : ZK.slate600)),
                if (leftSub != null)
                  Text(leftSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: dark ? Colors.white54 : ZK.slate400)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          right,
        ],
      ),
    );

Widget _yearChart(List<ChartBulan> data, bool dark, Color fg, Color muted, bool tablet) {
  final byBulan = {for (final c in data) c.bulan: c};
  final maxVal = data.fold<int>(1, (m, c) => [m, c.omzet, c.laba].reduce((a, b) => a > b ? a : b));
  final barMax = tablet ? 90.0 : 130.0;
  return SizedBox(
    height: tablet ? 120 : 160,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var m = 1; m <= 12; m++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _bar((byBulan[m]?.omzet ?? 0) / maxVal, ZK.primary, barMax),
                      const SizedBox(width: 2),
                      _bar((byBulan[m]?.laba ?? 0) / maxVal, ZK.amber700, barMax),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_bulanPendek[m - 1],
                      style: TextStyle(fontSize: 9, color: muted)),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _bar(double ratio, Color color, double maxHeight) => Container(
      width: 5,
      height: (ratio.clamp(0, 1) * maxHeight) + 2,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
