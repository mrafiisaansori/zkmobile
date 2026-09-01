import '_util.dart';

// ===== Pembelian barang (padanan services/pembelian.service.ts) =====
class PembelianDetail {
  final int id, idProduk, hargaBeli, qty;
  final String? namaProduk;
  PembelianDetail.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        idProduk = i(j['ID_PRODUK']),
        hargaBeli = i(j['HARGA_BELI']),
        qty = i(j['QTY']),
        namaProduk = s(j['produk']?['NAMA']);
  int get subtotal => hargaBeli * qty;
}

class Pembelian {
  final int id, status;
  final String noNota;
  final String? tanggal, catatan, namaSupplier;
  final int? idSupplier;
  final List<PembelianDetail> detail;
  Pembelian.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        noNota = '${j['NO_NOTA'] ?? ''}',
        tanggal = s(j['TANGGAL']),
        status = i(j['STATUS']),
        catatan = s(j['CATATAN']),
        idSupplier = j['ID_SUPPLIER'] == null ? null : i(j['ID_SUPPLIER']),
        namaSupplier = s(j['supplier']?['NAMA']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => PembelianDetail.fromJson(e as Map<String, dynamic>))
            .toList();
  int get total => detail.fold(0, (s, d) => s + d.subtotal);
}
