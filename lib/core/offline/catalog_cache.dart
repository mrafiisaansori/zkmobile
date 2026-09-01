import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/models.dart';

// Cache lokal katalog (produk/kategori/metode bayar/pajak) — supaya kasir
// tetap bisa lihat & jual produk saat koneksi putus. Disimpan sebagai JSON
// mentah yang bentuknya sama dengan respons server, jadi bisa lewat
// fromJson() yang sama persis, tanpa perlu model terpisah.
const _kProduk = 'zk_cache_produk';
const _kKategori = 'zk_cache_kategori';
const _kJenisBayar = 'zk_cache_jenisbayar';
const _kTax = 'zk_cache_tax';
const _kModifierPrefix = 'zk_cache_modifier_';

Map<String, dynamic> _produkJson(Produk p) => {
      'ID': p.id,
      'NAMA': p.nama,
      'STOK': p.stok,
      'HARGA_JUAL': p.hargaJual,
      'FOTO_URL': p.foto,
      if (p.satuan != null) 'satuan': {'NAMA': p.satuan},
    };
Map<String, dynamic> _kategoriJson(Kategori k) => {'ID': k.id, 'DESKRIPSI': k.deskripsi};
Map<String, dynamic> _jenisBayarJson(JenisBayar j) => {'ID': j.id, 'NAMA': j.nama};
Map<String, dynamic> _taxJson(TaxSetting t) => {
      'PPN_ENABLED': t.ppnOn,
      'SERVICE_ENABLED': t.serviceOn,
      'PPN_PERSEN': t.ppnPersen,
      'SERVICE_PERSEN': t.servicePersen,
    };

Future<void> _write(String key, Object jsonValue) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(key, jsonEncode(jsonValue));
}

Future<List<Map<String, dynamic>>?> _readList(String key) async {
  final sp = await SharedPreferences.getInstance();
  final raw = sp.getString(key);
  if (raw == null) return null;
  try {
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return null;
  }
}

Future<void> cacheProduk(List<Produk> list) =>
    _write(_kProduk, list.map(_produkJson).toList());
Future<List<Produk>> readCachedProduk() async =>
    (await _readList(_kProduk))?.map(Produk.fromJson).toList() ?? [];

Future<void> cacheKategori(List<Kategori> list) =>
    _write(_kKategori, list.map(_kategoriJson).toList());
Future<List<Kategori>> readCachedKategori() async =>
    (await _readList(_kKategori))?.map(Kategori.fromJson).toList() ?? [];

Future<void> cacheJenisBayar(List<JenisBayar> list) =>
    _write(_kJenisBayar, list.map(_jenisBayarJson).toList());
Future<List<JenisBayar>> readCachedJenisBayar() async =>
    (await _readList(_kJenisBayar))?.map(JenisBayar.fromJson).toList() ?? [];

Future<void> cacheTax(TaxSetting? t) async {
  if (t == null) return;
  await _write(_kTax, _taxJson(t));
}

Future<TaxSetting?> readCachedTax() async {
  final sp = await SharedPreferences.getInstance();
  final raw = sp.getString(_kTax);
  if (raw == null) return null;
  try {
    return TaxSetting.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _modifierGroupJson(ModifierGroup g) => {
      'ID': g.id,
      'NAMA': g.nama,
      'TIPE': g.tipe,
      'WAJIB': g.wajib,
      'options': [
        for (final o in g.options) {'ID': o.id, 'NAMA': o.nama, 'HARGA': o.harga},
      ],
    };

// Modifier per produk — supaya produk yang punya varian tetap bisa masuk
// keranjang saat offline (sebelumnya wajib panggil API tiap kali disentuh).
Future<void> cacheModifier(int produkId, List<ModifierGroup> groups) =>
    _write('$_kModifierPrefix$produkId', groups.map(_modifierGroupJson).toList());

Future<List<ModifierGroup>?> readCachedModifier(int produkId) async {
  final list = await _readList('$_kModifierPrefix$produkId');
  if (list == null) return null;
  return list.map(ModifierGroup.fromJson).toList();
}
