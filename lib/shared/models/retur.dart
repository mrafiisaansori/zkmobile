import '_util.dart';

// ===== Retur barang (padanan services/retur.service.ts) =====
class ReturDetail {
  final int id, idProduk, qty;
  final int? harga;
  final String? namaProduk, alasan, kondisi;
  ReturDetail.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        idProduk = i(j['ID_PRODUK']),
        qty = i(j['QTY']),
        harga = j['HARGA'] == null ? null : i(j['HARGA']),
        namaProduk = s(j['produk']?['NAMA']),
        alasan = s(j['ALASAN']),
        kondisi = s(j['KONDISI']);
}

class Retur {
  final int id, status;
  final String noNota;
  final String? tanggal, catatan, namaSupplier, noNotaPembelian;
  final int? idSupplier, idPembelian;
  final List<ReturDetail> detail;
  Retur.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        noNota = '${j['NO_NOTA'] ?? ''}',
        tanggal = s(j['TANGGAL']),
        status = i(j['STATUS']),
        catatan = s(j['CATATAN']),
        idSupplier = j['ID_SUPPLIER'] == null ? null : i(j['ID_SUPPLIER']),
        namaSupplier = s(j['supplier']?['NAMA']),
        idPembelian = j['ID_PEMBELIAN'] == null ? null : i(j['ID_PEMBELIAN']),
        noNotaPembelian = s(j['pembelian']?['NO_NOTA']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => ReturDetail.fromJson(e as Map<String, dynamic>))
            .toList();
}
