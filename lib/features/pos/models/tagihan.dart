import '../../../shared/models/models.dart';
import 'cart_item.dart';

// Rincian tagihan: subtotal - diskon - voucher, lalu PPN & service (plan PRO/BUSINESS).
class Tagihan {
  final int subtotal, diskon, voucher, ppn, service;
  Tagihan(this.subtotal, this.diskon, this.voucher, this.ppn, this.service);

  factory Tagihan.hitung({
    required List<CartItem> items,
    int diskon = 0,
    int voucher = 0,
    TaxSetting? tax,
    bool isPro = false,
  }) {
    final subtotal = items.fold<int>(0, (s, i) => s + i.total);
    final potong = (diskon + voucher) > subtotal ? subtotal : (diskon + voucher);
    final dpp = subtotal - potong;
    final ppn =
        isPro && (tax?.ppnOn ?? false) ? (dpp * tax!.ppnPersen / 100).round() : 0;
    final svc = isPro && (tax?.serviceOn ?? false)
        ? (dpp * tax!.servicePersen / 100).round()
        : 0;
    return Tagihan(
        subtotal, diskon > subtotal ? subtotal : diskon, potong - (diskon > subtotal ? subtotal : diskon), ppn, svc);
  }

  int get dpp => subtotal - diskon - voucher;
  int get total => dpp + ppn + service;
  int kembalian(int bayar) => bayar - total;
}
