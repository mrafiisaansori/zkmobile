import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'theme.dart';

// Padanan src/app/admin/laporan/page.tsx (FinanceDashboard) — omzet/laba/PPN
// per periode + rekap lengkap (PRO/BUSINESS). Tabel transaksi mentah sengaja
// tidak diulang di sini (sudah ada di menu Laporan Transaksi); export
// Excel/PDF juga dilewati (fitur sekunder, web-only untuk saat ini).
class AdminKeuanganPage extends StatefulWidget {
  const AdminKeuanganPage({super.key});
  @override
  State<AdminKeuanganPage> createState() => _AdminKeuanganPageState();
}

class _AdminKeuanganPageState extends State<AdminKeuanganPage> {
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 6)), end: DateTime.now());
  LaporanPenjualan? _penjualan;
  LaporanPendapatan? _pendapatan;
  RekapLaporan? _rekap;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dari = _iso(_range.start), sampai = _iso(_range.end);
      final results =
          await Future.wait([Api.laporanPenjualan(dari, sampai), Api.laporanPendapatan(dari, sampai)]);
      if (!mounted) return;
      final rekap = await Api.laporanRekap(dari, sampai);
      if (!mounted) return;
      setState(() {
        _penjualan = results[0] as LaporanPenjualan;
        _pendapatan = results[1] as LaporanPendapatan;
        _rekap = rekap;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _range,
        locale: const Locale('id'));
    if (r == null) return;
    setState(() => _range = r);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate500;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text('${_iso(_range.start)} → ${_iso(_range.end)}',
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
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : (_error != null || _penjualan == null || _pendapatan == null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error ?? 'Gagal memuat laporan',
                                  textAlign: TextAlign.center, style: TextStyle(color: fg)),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: Builder(builder: (context) {
                          final tablet = isTablet(context);
                          // Tablet: Row of Expanded (tinggi ikut konten), bukan
                          // GridView beraspek-rasio tetap — di layar lebar itu
                          // bikin sel jauh lebih tinggi dari kontennya.
                          final statRow = tablet
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: _statCard('Omzet (bersih, tanpa PPN)', rupiah(_penjualan!.omzet),
                                          Icons.account_balance_wallet_outlined, const Color(0xFF047857), dark)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _statCard('Jumlah transaksi', '${_penjualan!.jumlahTransaksi}',
                                          Icons.receipt_long_outlined, ZK.primary, dark)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _statCard('PPN terkumpul', rupiah(_penjualan!.totalPpn),
                                          Icons.receipt_outlined, ZK.amber700, dark)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _statCard('Laba kotor', rupiah(_pendapatan!.laba), Icons.trending_up,
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
                                    _statCard('Omzet (bersih, tanpa PPN)', rupiah(_penjualan!.omzet),
                                        Icons.account_balance_wallet_outlined, const Color(0xFF047857), dark),
                                    _statCard('Jumlah transaksi', '${_penjualan!.jumlahTransaksi}',
                                        Icons.receipt_long_outlined, ZK.primary, dark),
                                    _statCard('PPN terkumpul', rupiah(_penjualan!.totalPpn),
                                        Icons.receipt_outlined, ZK.amber700, dark),
                                    _statCard('Laba kotor', rupiah(_pendapatan!.laba), Icons.trending_up,
                                        const Color(0xFF047857), dark),
                                  ],
                                );
                          final supportRow = tablet
                              ? Row(
                                  children: [
                                    Expanded(child: _supportStat('Modal (HPP)', rupiah(_pendapatan!.modal), fg, muted)),
                                    Expanded(child: _supportStat(
                                        'Service charge', rupiah(_penjualan!.totalService), fg, muted)),
                                    Expanded(child: _supportStat('PPN (titipan pajak)', rupiah(_penjualan!.totalPpn), fg, muted)),
                                    Expanded(child: _supportStat(
                                        'Total diterima (bruto)', rupiah(_penjualan!.totalDibayar), fg, muted)),
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
                                    _supportStat('Modal (HPP)', rupiah(_pendapatan!.modal), fg, muted),
                                    _supportStat(
                                        'Service charge', rupiah(_penjualan!.totalService), fg, muted),
                                    _supportStat('PPN (titipan pajak)', rupiah(_penjualan!.totalPpn), fg, muted),
                                    _supportStat(
                                        'Total diterima (bruto)', rupiah(_penjualan!.totalDibayar), fg, muted),
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
                            if (_rekap == null)
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
                                  _rekap!.perMetodeBayar
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
                                  _rekap!.perKasir
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
                                  _rekap!.produkTerlaris
                                      .map((p) => ('${p.nama} (${p.qty})', rupiah(p.omzet)))
                                      .toList()),
                              const SizedBox(height: 14),
                              _breakdownCard(
                                  dark,
                                  fg,
                                  'Produk stok menipis',
                                  _rekap!.produkStokMenipis
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
