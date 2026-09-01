import '_util.dart';

class DetailPenjualan {
  final int qty, hargaJual, diskon;
  final String namaProduk;
  final String? modifier, satuan;
  DetailPenjualan.fromJson(Map<String, dynamic> j)
      : qty = i(j['QTY']),
        hargaJual = i(j['HARGA_JUAL']),
        diskon = i(j['DISKON']),
        namaProduk = '${j['produk']?['NAMA'] ?? '-'}',
        modifier = s(j['MODIFIER']),
        satuan = s(j['SATUAN']);

  int get subtotal => qty * hargaJual - diskon;
}

class Penjualan {
  final int id, total, status;
  final String? noNota, tanggal, jam, keterangan, jenisBayar, statusBayar,
      namaMember, namaKasir;
  final int noNotaUrut;
  final List<DetailPenjualan> detail;
  Penjualan.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        total = i(j['TOTAL']),
        status = j['STATUS'] == null ? 1 : i(j['STATUS']),
        noNota = s(j['NO_NOTA']),
        noNotaUrut = i(j['NO_NOTA_URUT']),
        tanggal = s(j['TANGGAL']),
        jam = s(j['JAM']),
        keterangan = s(j['KETERANGAN']),
        jenisBayar = s(j['jenisBayar']?['NAMA']),
        statusBayar = s(j['STATUS_BAYAR']),
        namaMember = s(j['member']?['NAMA']),
        namaKasir = s(j['kasir']?['NAMA']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => DetailPenjualan.fromJson(e as Map<String, dynamic>))
            .toList();

  // Padanan nomorNotaPenjualanLabel di web: pakai NO_NOTA, fallback ke urut/ID.
  String get label =>
      noNota ?? (noNotaUrut > 0 ? '#$noNotaUrut' : '#$id');
}
