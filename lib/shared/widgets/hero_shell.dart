import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/navigation/active_tab_cubit.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/screens/login_page.dart';
import 'theme_toggle.dart';

// Shell seragam untuk 4 tab (Dashboard/POS/Open Bill/Riwayat): header hero
// pakai ilustrasi yang sama seperti login, logo putih kiri, toggle tema +
// logout kanan, lalu konten dibungkus card putih/gelap yang menimpa ke atas
// (padanan gaya card login), sedikit overlap ke bawah ilustrasi.
class HeroShell extends StatelessWidget {
  final Widget child;
  // Override judul/subjudul header tablet — kalau null, dibaca dari
  // ActiveTabCubit/tabTitles (dipakai KasirShell). Halaman di luar shell
  // kasir (mis. admin) pakai override ini supaya tidak numpang tab kasir.
  final String? titleOverride, subtitleOverride;
  // Tombol hamburger di header ponsel (kiri, sebelum logo) — dipakai admin
  // buat buka Drawer, karena admin punya terlalu banyak menu buat bottom nav.
  final VoidCallback? onMenuTap;
  const HeroShell(
      {super.key,
      required this.child,
      this.titleOverride,
      this.subtitleOverride,
      this.onMenuTap});
  static const _heroH = 128.0;
  // Header tablet tetap lebih ramping dari ponsel (sidebar bawa branding
  // sendiri), tapi diberi sedikit lebih tinggi dari revisi awal.
  static const _heroHTablet = 96.0;

  Future<void> _logout(BuildContext context) async {
    await Session.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tablet = isTablet(context);
    final heroH = tablet ? _heroHTablet : _heroH;
    // Card konten tablet dibuat siku (tanpa rounded) — cuma ponsel yang
    // menimpa ilustrasi dengan lengkungan ala card login.
    final radius = tablet ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(28));
    final card = Container(
      decoration: BoxDecoration(color: dark ? ZK.cardDark : Colors.white, borderRadius: radius),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            const _OfflineStrip(),
            Expanded(child: child),
          ],
        ),
      ),
    );
    return Stack(
      children: [
        // Ilustrasi mengisi seluruh background, konten menimpa di atasnya.
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/login_illustration.jpeg',
                  fit: BoxFit.cover, alignment: const Alignment(0, -0.35)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(
              height: heroH,
              width: double.infinity,
              child: tablet ? _tabletHeader(context) : _phoneHeader(context),
            ),
            // Tablet: konten dibatasi lebar & dipusatkan (ilustrasi tetap
            // kelihatan di kiri-kanan) alih-alih melebar penuh layar lanskap.
            Expanded(
              child: tablet
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: card,
                      ),
                    )
                  : card,
            ),
          ],
        ),
      ],
    );
  }

  // Header ponsel: ilustrasi login + logo/wordmark kiri, toggle tema +
  // logout kanan (tidak berubah dari sebelumnya).
  Widget _phoneHeader(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 10, 0),
          child: Row(
            children: [
              if (onMenuTap != null) ...[
                _headerIcon(icon: Icons.menu, tooltip: 'Menu', onTap: onMenuTap!),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/logo_splash.png', height: 24, width: 24),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ZONA KASIR',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                          height: 1.1)),
                  Text('Solusi Bisnis Anda',
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              const ThemeToggle(height: 30),
              const SizedBox(width: 8),
              _headerIcon(
                icon: Icons.logout,
                tooltip: 'Keluar',
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      );

  // Header tablet: banner aksen + judul halaman aktif (sidebar sudah bawa
  // branding/toggle/logout sendiri) + jam saat ini di kanan.
  Widget _tabletHeader(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/banner_header.jpeg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color.fromRGBO(10, 37, 64, 0.93), Color.fromRGBO(10, 37, 64, 0.8)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (titleOverride != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(titleOverride!,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        if (subtitleOverride != null)
                          Text(subtitleOverride!,
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    )
                  else
                    BlocBuilder<ActiveTabCubit, int>(
                      builder: (_, tab) {
                        final t = tabTitles[tab.clamp(0, tabTitles.length - 1)];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.$1,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text(t.$2,
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        );
                      },
                    ),
                  const Spacer(),
                  Text(_now(),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      );

  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jumat", 'Sabtu', 'Minggu'];
  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  String _now() {
    final n = DateTime.now();
    final jam = n.hour.toString().padLeft(2, '0');
    final menit = n.minute.toString().padLeft(2, '0');
    return '${_hari[n.weekday - 1]}, ${n.day} ${_bulan[n.month - 1]} ${n.year} · $jam:$menit';
  }

  // Chip lingkaran gelap di belakang ikon supaya tetap kontras di atas
  // ilustrasi terang maupun gelap.
  Widget _headerIcon(
          {required IconData icon, required String tooltip, required VoidCallback onTap}) =>
      Material(
        color: Colors.black.withValues(alpha: 0.32),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
          icon: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

// Strip peringatan yang selalu terlihat selama koneksi terputus — muncul di
// semua halaman lewat HeroShell, bukan cuma toast sekali lewat.
class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip();
  @override
  Widget build(BuildContext context) => BlocBuilder<ConnectivityCubit, bool>(
        builder: (_, offline) => AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: offline
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: ZK.amber700,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('OFFLINE: pakai data tersimpan terakhir',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2)),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      );
}
