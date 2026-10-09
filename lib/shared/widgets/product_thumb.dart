import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Gambar produk dengan fallback ikon (padanan ProductImage + productImage()).
class ProductThumb extends StatelessWidget {
  final String? url;
  final double size;
  const ProductThumb({super.key, required this.url, this.size = 44});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
            color: dark ? ZK.bgDark : ZK.slate50, borderRadius: r12),
        child: url == null
            ? Icon(Icons.inventory_2_outlined,
                size: size * 0.45, color: ZK.slate400)
            : ClipRRect(
                borderRadius: r12,
                child: Image.network(url!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        size: size * 0.45,
                        color: ZK.slate400)),
              ),
      );
  }
}
