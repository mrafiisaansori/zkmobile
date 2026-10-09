import '_util.dart';
import 'member.dart';

class OpenBillDetail {
  final int id, idProduk, hargaJual, qty, paidQty;
  final String namaProduk;
  final int stok;
  final String? modifier, modifierOptions;
  OpenBillDetail.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        idProduk = i(j['ID_PRODUK']),
        hargaJual = i(j['HARGA_JUAL']),
        qty = i(j['QTY']),
        paidQty = i(j['PAID_QTY']),
        namaProduk = s(j['produk']?['NAMA']) ?? 'Produk ${i(j['ID_PRODUK'])}',
        stok = i(j['produk']?['STOK'] ?? j['QTY']),
        modifier = s(j['MODIFIER']),
        modifierOptions = s(j['MODIFIER_OPTIONS']);

  int get sisaQty => qty - paidQty;
}

class OpenBill {
  final int id, total;
  final String status;
  final String? noBill, customerName, tableNo, note, kasir, createdAt;
  final List<OpenBillDetail> detail;
  // Member pelanggan bill (null bila tanpa member). Backend memakainya saat bill dibayar.
  final Member? member;
  // Daftar /open-bill bisa hanya membawa MEMBER_ID tanpa object member.
  final int? memberId;
  OpenBill.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        total = i(j['TOTAL']),
        status = '${j['STATUS'] ?? 'OPEN'}',
        noBill = s(j['NO_BILL']),
        customerName = s(j['CUSTOMER_NAME']),
        tableNo = s(j['TABLE_NO']),
        note = s(j['NOTE']),
        kasir = s(j['kasir']?['NAMA']),
        createdAt = s(j['CREATED_AT']),
        member = j['member'] is Map<String, dynamic> ? Member.fromJson(j['member']) : null,
        memberId = j['MEMBER_ID'] == null ? null : i(j['MEMBER_ID']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => OpenBillDetail.fromJson(e as Map<String, dynamic>))
            .toList();
}
