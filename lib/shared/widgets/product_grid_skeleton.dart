import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Skeleton grid saat produk pertama kali dimuat — terasa lebih cepat
// daripada layar kosong + spinner tengah.
class ProductGridSkeleton extends StatefulWidget {
  const ProductGridSkeleton({super.key});
  @override
  State<ProductGridSkeleton> createState() => _ProductGridSkeletonState();
}

class _ProductGridSkeletonState extends State<ProductGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  late final _fade = Tween(begin: 0.4, end: 0.85).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? Colors.white12 : const Color(0xFFE9EEF3);
    // Samakan jumlah kolom skeleton dengan grid produk asli (4 di tablet, 2
    // di ponsel), supaya ukuran kartu placeholder tidak beda dari aslinya.
    final tablet = isTablet(context);
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: tablet ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.80,
          ),
          itemCount: tablet ? 8 : 6,
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? ZK.cardDark : Colors.white,
              borderRadius: r12,
              border: Border.all(color: dark ? ZK.lineDark : ZK.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: base, borderRadius: r12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 12, width: 90, color: base),
                const SizedBox(height: 6),
                Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                        color: base, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 8),
                Container(height: 15, width: 70, color: base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
