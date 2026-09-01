import '../../../shared/models/models.dart';

// ===== Keranjang =====
int _lineSeq = 0;

// Satu baris keranjang. Baris dengan varian selalu terpisah, sama seperti web.
class CartItem {
  final String lineId;
  final Produk produk;
  final int? openBillDetailId;
  final List<ModifierOption> modifiers;
  int qty;
  int stokOverride;

  CartItem(this.produk, this.qty,
      {this.modifiers = const [], this.openBillDetailId, int? stok})
      : lineId = 'l${_lineSeq++}',
        stokOverride = stok ?? produk.stok;

  int get modifierExtra => modifiers.fold(0, (s, m) => s + m.harga);
  int get unit => produk.hargaJual + modifierExtra;
  int get total => unit * qty;
  int get stok => stokOverride;
  String? get modifierText =>
      modifiers.isEmpty ? null : modifiers.map((m) => m.nama).join(', ');
  List<int> get modifierIds => modifiers.map((m) => m.id).toList();
}
