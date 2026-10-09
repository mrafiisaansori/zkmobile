import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/models.dart';
import '../models/bill_context.dart';
import '../models/cart_item.dart';
import 'cart_state.dart';

// Padanan stores/cartStore.ts / lib/cart.dart lama (Cart extends
// ChangeNotifier). Satu instance dibuat di root MultiBlocProvider (app.dart)
// dan dibagi ke POS + Open Bill lewat context.read<CartCubit>(), persis
// seperti Cart.i singleton sebelumnya — cuma method-nya sekarang emit(state)
// yang baru alih-alih mutasi in-place + notifyListeners().
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  // Tambah produk tanpa varian: digabung dengan baris polos yang sama.
  CartResult addItem(Produk p) {
    if (p.stok <= 0) return const CartResult(false, 'Stok produk habis');
    final idx = state.items
        .indexWhere((i) => i.produk.id == p.id && i.modifiers.isEmpty);
    if (idx >= 0) {
      final existing = state.items[idx];
      if (existing.qty + 1 > p.stok) {
        return const CartResult(false, 'Qty melebihi stok');
      }
      final items = [...state.items];
      items[idx] = existing..qty = existing.qty + 1;
      emit(state.copyWith(items: items));
    } else {
      emit(state.copyWith(items: [...state.items, CartItem(p, 1)]));
    }
    return const CartResult(true);
  }

  // Produk dengan varian selalu jadi baris baru (sama seperti addLine di web).
  CartResult addLine(Produk p, List<ModifierOption> options) {
    if (p.stok <= 0) return const CartResult(false, 'Stok produk habis');
    emit(state.copyWith(
        items: [...state.items, CartItem(p, 1, modifiers: options)]));
    return const CartResult(true);
  }

  CartResult updateQty(CartItem it, int qty) {
    if (qty <= 0) {
      remove(it);
      return const CartResult(true);
    }
    if (qty > it.stok) return const CartResult(false, 'Qty melebihi stok');
    final items = [...state.items];
    final idx = items.indexOf(it);
    if (idx >= 0) items[idx] = it..qty = qty;
    emit(state.copyWith(items: items));
    return const CartResult(true);
  }

  void remove(CartItem it) {
    emit(state.copyWith(items: state.items.where((e) => e != it).toList()));
  }

  void setDiskon(int n) => emit(state.copyWith(diskon: n < 0 ? 0 : n));

  void setMember(Member? m) => m == null
      ? emit(state.copyWith(clearMember: true))
      : emit(state.copyWith(member: m));

  void setVoucher(VoucherPreview? v) => v == null
      ? emit(state.copyWith(clearVoucher: true))
      : emit(state.copyWith(voucher: v));

  void setBillMeta({String? customer, String? table, String? note}) {
    final b = state.bill;
    if (b == null) return;
    if (customer != null) b.customerName = customer;
    if (table != null) b.tableNo = table;
    if (note != null) b.note = note;
    emit(state.copyWith(bill: b));
  }

  void clear() => emit(const CartState());

  // Muat open bill ke keranjang. Item yang sudah dibayar sebagian (PAID_QTY)
  // disisakan sesuai sisa qty-nya, sama seperti loadBill di web.
  void loadBill(OpenBill b) {
    final items = <CartItem>[];
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
    emit(CartState(
      items: items,
      bill: BillContext(b.id, b.noBill, b.customerName ?? '', b.tableNo ?? '',
          b.note ?? '', b.member?.id),
      member: b.member,
    ));
  }

  // Lengkapi foto item bill dari daftar produk POS (detail bill tidak bawa foto).
  void hydrateImages(List<Produk> produk) {
    var changed = false;
    final items = [...state.items];
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
    if (changed) emit(state.copyWith(items: items));
  }
}
