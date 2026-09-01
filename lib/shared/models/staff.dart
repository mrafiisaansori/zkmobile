import '_util.dart';

class Pengguna {
  final int id, level;
  final String nama, username;
  final String? telp;
  Pengguna.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        username = '${j['USERNAME'] ?? ''}',
        level = i(j['LEVEL']),
        telp = s(j['TELP']);

  // 1 = Admin (tidak bisa dibuat/diubah dari layar ini), 2 = Kasir, 3 = Gudang.
  String get roleLabel => level == 1 ? 'Admin' : level == 3 ? 'Gudang' : 'Kasir';
}
