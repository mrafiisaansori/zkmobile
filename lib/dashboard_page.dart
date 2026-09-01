import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'shell.dart';
import 'theme.dart';
import 'sheets.dart';
import 'widgets.dart';

// Padanan src/app/kasir/dashboard/page.tsx.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  int _total = 0, _jumlah = 0;
  List<Penjualan> _data = [];
  bool _shiftActive = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _hariIni => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _load() async {
    setState(() => _loading = true);
    final aktif = await Api.shiftActive();
    try {
      final r = await Api.rekapHariIni(Session.user?.id ?? 0, _hariIni);
      if (!mounted) return;
      setState(() {
        _total = (r['total_dibayar'] as num?)?.toInt() ?? 0;
        _jumlah = (r['jumlah_transaksi'] as num?)?.toInt() ?? 0;
        _data = ((r['data'] as List?) ?? [])
            .map((e) => Penjualan.fromJson(e as Map<String, dynamic>))
            .toList();
        _shiftActive = aktif;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _shiftActive = aktif);
        toastError(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bukaSesi() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BukaSesiSheet(),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate600;
    final cardColor = dark ? ZK.cardDark : Colors.white;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    return HeroShell(
      child: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          color: ZK.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text('Ringkasan kasir hari ini (${_tanggalPanjang()})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
              const SizedBox(height: 14),
              _welcomeBanner(dark, isTablet(context)),
              const SizedBox(height: 16),
              if (!_shiftActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShiftBanner(onBuka: _bukaSesi),
                ),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Penjualan hari ini',
                      value: rupiah(_total),
                      icon: Icons.account_balance_wallet_outlined,
                      tone: const Color(0xFF10B981),
                      loading: _loading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Transaksi hari ini',
                      value: '$_jumlah',
                      icon: Icons.receipt_outlined,
                      tone: ZK.primary,
                      loading: _loading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => KasirShell.of(context).goTo(1),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: const Text('Mulai Transaksi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary,
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: r14,
                  border: Border.all(color: lineColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Transaksi terbaru',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
                        ),
                        TextButton(
                          onPressed: () => KasirShell.of(context).goTo(4),
                          child: const Text('Lihat semua',
                              style: TextStyle(fontSize: 13, color: ZK.primary)),
                        ),
                      ],
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: CircularProgressIndicator(color: ZK.primary)),
                      )
                    else if (_data.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: EmptyState(
                            title: 'Belum ada transaksi hari ini',
                            description: 'Mulai transaksi dari tab Kasir.'),
                      )
                    else
                      for (final p in _data) _trxRow(p, fg, muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trxRow(Penjualan p, Color fg, Color muted) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.label,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                  Text(p.jam ?? '-', style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
            Text(rupiah(p.total),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
          ],
        ),
      );

  // Banner promo/branding — biar dashboard tidak cuma angka & tabel,
  // sekaligus penguat identitas visual (padanan hero section di web).
  // Tablet: tanpa ilustrasi foto (sidebar & header sudah bawa visual sendiri,
  // dashboard tinggal warna polos biar tidak berebut perhatian).
  Widget _welcomeBanner(bool dark, bool tablet) => ClipRRect(
        borderRadius: r14,
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (tablet)
                const DecoratedBox(decoration: BoxDecoration(color: ZK.ink))
              else
                Image.asset('assets/dashboard_banner.jpeg',
                    fit: BoxFit.cover, alignment: Alignment.center),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.62, 1],
                    colors: [
                      ZK.ink.withValues(alpha: 0.92),
                      ZK.ink.withValues(alpha: 0.75),
                      ZK.ink.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Selamat Berjualan!',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1)),
                            ])),
                    const SizedBox(height: 4),
                    Text('Layani pelanggan lebih cepat dengan Zona Kasir.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.92),
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1)),
                            ])),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  String _tanggalPanjang() {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final d = DateTime.now();
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color tone;
  final bool loading;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r14,
        border: Border.all(color: dark ? ZK.lineDark : ZK.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration:
                BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: r12),
            child: Icon(icon, size: 18, color: tone),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : ZK.slate600)),
          const SizedBox(height: 4),
          loading
              ? const SizedBox(
                  height: 26,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ZK.primary)),
                  ),
                )
              : Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : ZK.ink)),
        ],
      ),
    );
  }
}
