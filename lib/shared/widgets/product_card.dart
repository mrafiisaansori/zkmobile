import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/formatters.dart';
import '../models/models.dart';

// ===== Kartu produk (padanan components/pos/ProductGrid.tsx) =====
class ProductCard extends StatelessWidget {
  final Produk produk;
  final VoidCallback onAdd;
  const ProductCard({super.key, required this.produk, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final habis = produk.stok <= 0;
    // Nada badge stok mengikuti web: habis=rose, <=10 amber, sisanya brand.
    final (bg, fg) = habis
        ? (ZK.rose50, ZK.rose)
        : produk.stok <= 10
            ? (ZK.amber50, ZK.amber700)
            : (ZK.brand50, ZK.brand700);

    return Opacity(
      opacity: habis ? 0.6 : 1,
      child: Material(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r12,
        child: InkWell(
          borderRadius: r12,
          onTap: habis ? null : onAdd,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: r12,
              border: Border.all(color: habis ? (dark ? ZK.lineDark : ZK.line) : ZK.brand200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: produk.foto == null
                        ? const Icon(Icons.inventory_2_outlined,
                            size: 40, color: ZK.slate400)
                        : Image.network(produk.foto!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                                color: ZK.slate400)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(produk.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.slate900)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                      'Stok ${produk.stok}${produk.satuan != null ? ' ${produk.satuan}' : ''}',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(rupiah(produk.hargaJual),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : ZK.slate900)),
                    ),
                    if (!habis)
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            color: ZK.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9)),
                        child:
                            const Icon(Icons.add, size: 18, color: ZK.primary),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
