import '_util.dart';

class Member {
  final int id;
  final String nama, noHp;
  final String? kode;
  // Field tambahan dipakai halaman admin (Master Member) — kasir cuma pakai
  // id/nama/noHp/kode buat member-picker, sisanya opsional/nullable.
  final String? email, alamat, tanggalDaftar;
  final int status;
  Member.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        noHp = '${j['NO_HP'] ?? ''}',
        kode = s(j['KODE_MEMBER']),
        email = s(j['EMAIL']),
        alamat = s(j['ALAMAT']),
        tanggalDaftar = s(j['TANGGAL_DAFTAR']),
        status = j['STATUS'] == null ? 1 : i(j['STATUS']);
}
