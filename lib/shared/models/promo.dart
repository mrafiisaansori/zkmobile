import '_util.dart';

class VoucherPreview {
  final String kode;
  final int diskon;
  VoucherPreview.fromJson(Map<String, dynamic> j)
      : kode = '${j['kode'] ?? ''}',
        diskon = i(j['diskon']);
}

class Voucher {
  final int id, nilai, minTransaksi;
  final String kode, tipe;
  final String? validFrom, validUntil;
  final bool aktif;
  Voucher.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        kode = '${j['KODE'] ?? ''}',
        tipe = '${j['TIPE'] ?? 'NOMINAL'}',
        nilai = i(j['NILAI']),
        minTransaksi = i(j['MIN_TRANSAKSI']),
        validFrom = s(j['VALID_FROM']),
        validUntil = s(j['VALID_UNTIL']),
        aktif = j['IS_ACTIVE'] == true;
  bool get persen => tipe == 'PERSEN';
}
