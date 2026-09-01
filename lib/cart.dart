import 'package:flutter/foundation.dart';
import 'models.dart';

// Konteks open bill yang sedang diedit (null = transaksi langsung biasa).
class BillContext {
  final int id;
  final String? noBill;
  String customerName, tableNo, note;
  BillContext(this.id, this.noBill, this.customerName, this.tableNo, this.note);
}

class CartResult {
  final bool ok;
  final String? message;
  const CartResult(this.ok, [this.message]);
}

// Padanan stores/cartStore.ts. Satu instance global — POS dan Open Bill
// berbagi keranjang yang sama, persis seperti zustand di web.
class Cart extends ChangeNotifier {
  static final Cart i = Cart();

  final List<CartItem> items = [];
  int diskon = 0;
  BillContext? bill;
  Member? member;
  VoucherPreview? voucher;

  bool get billMode => bill != null;
  int get count => items.fold(0, (s, i) => s + i.qty);
  int get subtotal => items.fold(0, (s, i) => s + i.total);
  int get total {
    final t = subtotal - diskon - (voucher?.diskon ?? 0);
    return t < 0 ? 0 : t;
  }

  // Tambah produk tanpa varian: digabung dengan baris polos yang sama.
  CartResult addItem(Produk p) {
    if (p.stok <= 0) return const CartResult(false, 'Stok produk habis');
    final idx =
        items.indexWhere((i) => i.produk.id == p.id && i.modifiers.isEmpty);
    if (idx >= 0) {
      if (items[idx].qty + 1 > p.stok) {
        return const CartResult(false, 'Qty melebihi stok');
      }
      items[idx].qty++;
    } else {
      items.add(CartItem(p, 1));
    }
    notifyListeners();
    return const CartResult(true);
  }

  // Produk dengan varian selalu jadi baris baru (sama seperti addLine di web).
  CartResult addLine(Produk p, List<ModifierOption> options) {
    if (p.stok <= 0) return const CartResult(false, 'Stok produk habis');
    items.add(CartItem(p, 1, modifiers: options));
    notifyListeners();
    return const CartResult(true);
  }

  CartResult updateQty(CartItem it, int qty) {
    if (qty <= 0) {
      remove(it);
      return const CartResult(true);
    }
    if (qty > it.stok) return const CartResult(false, 'Qty melebihi stok');
    it.qty = qty;
    notifyListeners();
    return const CartResult(true);
  }

  void remove(CartItem it) {
    items.remove(it);
    notifyListeners();
  }

  void setDiskon(int n) {
    diskon = n < 0 ? 0 : n;
    notifyListeners();
  }

  void setMember(Member? m) {
    member = m;
    notifyListeners();
  }

  void setVoucher(VoucherPreview? v) {
    voucher = v;
    notifyListeners();
  }

  void setBillMeta({String? customer, String? table, String? note}) {
    final b = bill;
    if (b == null) return;
    if (customer != null) b.customerName = customer;
    if (table != null) b.tableNo = table;
    if (note != null) b.note = note;
    notifyListeners();
  }

  void clear() {
    items.clear();
    diskon = 0;
    bill = null;
    member = null;
    voucher = null;
    notifyListeners();
  }

  // Muat open bill ke keranjang. Item yang sudah dibayar sebagian (PAID_QTY)
  // disisakan sesuai sisa qty-nya, sama seperti loadBill di web.
  void loadBill(OpenBill b) {
    items.clear();
    diskon = 0;
    member = null;
    voucher = null;
    bill = BillContext(b.id, b.noBill, b.customerName ?? '', b.tableNo ?? '',
        b.note ?? '');
    for (final d in b.detail) {
      if (d.sisaQty <= 0) continue;
      items.add(CartItem(
        // HARGA_JUAL detail sudah harga efektif (termasuk varian).
        Produk.raw(d.idProduk, d.namaProduk, d.hargaJual, d.stok),
        d.sisaQty,
        openBillDetailId: d.id,
        stok: d.stok < d.sisaQty ? d.sisaQty : d.stok,
      ));
    }
    notifyListeners();
  }

  // Lengkapi foto item bill dari daftar produk POS (detail bill tidak bawa foto).
  void hydrateImages(List<Produk> produk) {
    var changed = false;
    for (var n = 0; n < items.length; n++) {
      final it = items[n];
      if (it.produk.foto != null) continue;
      final p = produk.where((x) => x.id == it.produk.id).firstOrNull;
      if (p == null) continue;
      items[n] = CartItem(
        Produk.raw(it.produk.id, it.produk.nama, it.produk.hargaJual, it.stok,
            foto: p.foto, satuan: p.satuan),
        it.qty,
        modifiers: it.modifiers,
        openBillDetailId: it.openBillDetailId,
        stok: it.stok,
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }
}
