import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';

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
    final svg = SvgPicture.asset(
      'assets/icons/menu/zk_duo_${name}_${active ? 'active' : 'inactive'}${isDark ? '_dark' : ''}.svg',
      width: size,
      height: size,
    );
    if (!active) return svg;
    // Bayangan lembut di bawah ikon aktif; ukuran tetap size×size.
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: ZK.primary.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: svg,
    );
  }
}
