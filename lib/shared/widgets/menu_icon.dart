import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Ikon menu duotone (assets/icons/menu/zk_duo_<name>_<active|inactive>[_dark].svg).
// [dark] memaksa varian gelap — dipakai item terpilih sidebar tablet yang
// berlatar biru, terlepas dari tema aktif.
class MenuIcon extends StatelessWidget {
  final String name;
  final bool active;
  final double size;
  final bool? dark;
  const MenuIcon({super.key, required this.name, required this.active, this.size = 24, this.dark});

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? Theme.of(context).brightness == Brightness.dark;
    // Tanpa glow: tab aktif sudah ditandai indikator latar NavigationBar.
    return SvgPicture.asset(
      'assets/icons/menu/zk_duo_${name}_${active ? 'active' : 'inactive'}${isDark ? '_dark' : ''}.svg',
      width: size,
      height: size,
    );
  }
}
