import '_util.dart';

class ModifierOption {
  final int id, harga;
  final String nama;
  ModifierOption.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        harga = i(j['HARGA']);
}

class ModifierGroup {
  final int id;
  final String nama, tipe;
  final bool wajib;
  final List<ModifierOption> options;
  ModifierGroup.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        tipe = '${j['TIPE'] ?? 'SINGLE'}',
        wajib = j['WAJIB'] == true,
        options = ((j['options'] as List?) ?? [])
            .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
            .toList();
  bool get single => tipe == 'SINGLE';
}
