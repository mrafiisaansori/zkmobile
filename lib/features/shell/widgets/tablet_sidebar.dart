import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
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
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        border: Border(right: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
      ),
      child: Column(
        children: [
          _header(dark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _item(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', dark),
                _item(1, Icons.point_of_sale_outlined, Icons.point_of_sale, 'Kasir', dark,
                    badge: cartCount > 0 ? '$cartCount' : null),
                _item(2, Icons.receipt_long_outlined, Icons.receipt_long, 'Open Bill', dark),
                _item(3, Icons.lock_open_outlined, Icons.lock_open, 'Buka/Tutup Kas', dark),
                _item(4, Icons.history_outlined, Icons.history, 'Riwayat', dark),
              ],
            ),
          ),
          _footer(context, dark),
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
                          TextStyle(fontSize: 10, color: dark ? Colors.white54 : ZK.slate500)),
                ],
              ),
            ),
          ],
        ),
      );

  // Satu item navigasi sidebar — terpilih = pil biru penuh lebar (padanan
  // desain mockup), bukan sekadar indikator kecil di sekitar ikon.
  Widget _item(int index, IconData icon, IconData selectedIcon, String label, bool dark,
      {String? badge}) {
    final selected = selectedIndex == index;
    final iconWidget = Icon(selected ? selectedIcon : icon,
        size: 20, color: selected ? Colors.white : (dark ? Colors.white60 : ZK.slate600));
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
                                fontSize: 10.5, color: dark ? Colors.white54 : ZK.slate500)),
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
