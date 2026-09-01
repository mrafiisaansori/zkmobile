import 'package:flutter_test/flutter_test.dart';
import 'package:zkkasir/shared/models/models.dart';
import 'package:zkkasir/features/pos/models/cart_item.dart';
import 'package:zkkasir/features/pos/models/tagihan.dart';

Produk _p(int harga, {int stok = 99}) => Produk.fromJson(
    {'ID': 1, 'NAMA': 'X', 'STOK': stok, 'HARGA_JUAL': harga});

void main() {
  final tax = TaxSetting.fromJson({
    'PPN_ENABLED': true,
    'PPN_PERSEN': 11,
    'SERVICE_ENABLED': true,
    'SERVICE_PERSEN': 5,
  });

  test('subtotal, diskon, voucher, pajak, kembalian', () {
    final items = [CartItem(_p(10000), 3)]; // 30.000

    // FREE: pajak diabaikan.
    final free = Tagihan.hitung(items: items, diskon: 5000, tax: tax);
    expect(free.total, 25000);
    expect(free.kembalian(50000), 25000);

    // PRO: PPN 11% + service 5% dari DPP (setelah diskon).
    final pro = Tagihan.hitung(items: items, diskon: 5000, tax: tax, isPro: true);
    expect(pro.ppn, 2750);
    expect(pro.service, 1250);
    expect(pro.total, 29000);

    // Voucher menambah potongan sebelum pajak.
    final v = Tagihan.hitung(items: items, diskon: 5000, voucher: 5000);
    expect(v.total, 20000);

    // Potongan melebihi subtotal tidak boleh bikin total negatif.
    expect(Tagihan.hitung(items: items, diskon: 99000).total, 0);
  });

  test('varian menambah harga satuan', () {
    final opt = ModifierOption.fromJson({'ID': 7, 'NAMA': 'Large', 'HARGA': 3000});
    final it = CartItem(_p(10000), 2, modifiers: [opt]);
    expect(it.unit, 13000);
    expect(it.total, 26000);
    expect(it.modifierIds, [7]);
    expect(it.modifierText, 'Large');
  });

  test('open bill hanya memuat sisa qty yang belum dibayar', () {
    final bill = OpenBill.fromJson({
      'ID': 5,
      'STATUS': 'OPEN',
      'TOTAL': 30000,
      'detail': [
        {'ID': 1, 'ID_PRODUK': 1, 'HARGA_JUAL': 10000, 'QTY': 3, 'PAID_QTY': 1},
        {'ID': 2, 'ID_PRODUK': 2, 'HARGA_JUAL': 5000, 'QTY': 2, 'PAID_QTY': 2},
      ],
    });
    expect(bill.detail[0].sisaQty, 2);
    expect(bill.detail[1].sisaQty, 0); // sudah lunas, tidak masuk keranjang
  });
}
