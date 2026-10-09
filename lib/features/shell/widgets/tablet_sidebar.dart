import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/screens/login_page.dart';

// Sidebar tablet reusable — dipakai KasirShell sendiri, dan juga halaman
// yang di-push di atasnya (mis. detail riwayat) lewat ShellCubit.instance
// supaya semua halaman tablet punya chrome yang sama persis.
// Padanan TabletSidebar lama di shell.dart, cuma badge keranjang sekarang
// dioper sebagai parameter (dibaca dari CartCubit oleh pemanggil) alih-alih
// baca Cart.i langsung, supaya widget ini tetap tidak terikat ke satu cubit.
class TabletSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool shiftActive;
  final int cartCount;
  const TabletSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.shiftActive,
    this.cartCount = 0,
  });

  Future<void> _logout(BuildContext context) async {
    await Session.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Di tab Kasir sidebar menyusut jadi rail 72px supaya grid produk lebih lega.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: selectedIndex == 1 ? 72 : 220,
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        border: Border(right: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
      ),
      child: ClipRect(
        child: LayoutBuilder(
          // Mode ditentukan dari lebar aktual, supaya selama animasi tidak
          // ada layout penuh yang dipaksa masuk ke lebar rail.
          builder: (context, c) {
            final rail = c.maxWidth < 140;
            final items = [
              ('dashboard', 'Dashboard'),
              ('kasir', 'Kasir'),
              ('openbill', 'Open Bill'),
              ('kas', 'Sesi Kas'),
              ('riwayat', 'Riwayat'),
            ];
            return Column(
              children: [
                rail
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Image.asset('assets/logo.png', height: 36, width: 36),
                      )
                    : _header(dark),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (var i = 0; i < items.length; i++)
                        (rail ? _railItem : _item)(i, items[i].$1, items[i].$2, dark,
                            badge: i == 1 && cartCount > 0 ? '$cartCount' : null),
                    ],
                  ),
                ),
                rail ? _railFooter(context, dark) : _footer(context, dark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _railItem(int index, String icon, String label, bool dark, {String? badge}) {
    final selected = selectedIndex == index;
    final iconWidget = MenuIcon(name: icon, active: false, size: 24, dark: selected ? true : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r12,
          onTap: () => onSelect(index),
          child: Container(
            height: 56,
            decoration: BoxDecoration(color: selected ? ZK.primary : null, borderRadius: r12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                badge == null ? iconWidget : Badge(label: Text(badge), child: iconWidget),
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : (dark ? Colors.white70 : ZK.slate600))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Footer rail: cukup toggle tema + logout.
  Widget _railFooter(BuildContext context, bool dark) {
    final color = dark ? Colors.white70 : ZK.slate600;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Divider(color: dark ? ZK.lineDark : ZK.line, indent: 12, endIndent: 12),
          IconButton(
            onPressed: () => context.read<ThemeCubit>().toggle(),
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20, color: color),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: Icon(Icons.logout, size: 20, color: color),
          ),
        ],
      ),
    );
  }

  // Header sidebar tablet: logo + wordmark — sidebar tablet selalu terbuka,
  // tidak ada tombol show/hide lagi.
  Widget _header(bool dark) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
        child: Row(
          children: [
            Image.asset('assets/logo.png', height: 36, width: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ZONA KASIR',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : ZK.ink)),
                  Text('Solusi Bisnis Anda',
                      style:
                          TextStyle(fontSize: 10, color: dark ? Colors.white60 : ZK.slate500)),
                ],
              ),
            ),
          ],
        ),
      );

  // Satu item navigasi sidebar — terpilih = pil biru penuh lebar (padanan
  // desain mockup), bukan sekadar indikator kecil di sekitar ikon.
  Widget _item(int index, String icon, String label, bool dark, {String? badge}) {
    final selected = selectedIndex == index;
    // Terpilih berlatar ZK.primary → varian inactive_dark supaya kontras di atas biru.
    final iconWidget =
        MenuIcon(name: icon, active: false, size: 20, dark: selected ? true : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r12,
          onTap: () => onSelect(index),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: selected ? ZK.primary : null, borderRadius: r12),
            child: Row(
              children: [
                badge == null
                    ? iconWidget
                    : Badge(label: Text(badge), child: iconWidget),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (dark ? Colors.white70 : ZK.slate600))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Blok profil kasir di bawah sidebar tablet (nama, status sesi, toggle
  // tema, logout).
  Widget _footer(BuildContext context, bool dark) {
    final nama = Session.user?.nama ?? '';
    final initials = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: dark ? ZK.lineDark : ZK.line),
          const SizedBox(height: 4),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ZK.brand100,
                child: Text(initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: ZK.brand700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nama.isEmpty ? '-' : nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : ZK.ink)),
                    Row(
                      children: [
                        Container(
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: shiftActive ? ZK.primary : ZK.slate400),
                        ),
                        const SizedBox(width: 4),
                        Text(shiftActive ? 'Sesi aktif' : 'Sesi tidak aktif',
                            style: TextStyle(
                                fontSize: 10.5, color: dark ? Colors.white60 : ZK.slate500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<ThemeCubit>().toggle(),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: dark ? Colors.white70 : ZK.slate600,
                      side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 17),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: dark ? Colors.white70 : ZK.slate600,
                      side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: const Icon(Icons.logout, size: 17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
