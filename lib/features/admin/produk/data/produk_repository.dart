import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Bungkus endpoint /produk, /kategori, /satuan, /modifier — padanan bagian
// produk di lib/api.dart lama. fetchPage() dibentuk supaya cocok dengan
// kontrak ListCubit<Produk> (limit 30/halaman, sama seperti Api.produk()).
class ProdukRepository {
  Future<List<Produk>> fetchPage({String? search, int page = 1}) async =>
      apiList<Produk>(
          await apiGet('/produk', {
            'search': (search ?? '').isEmpty ? null : search,
            'category_id': 'all',
            'page': page,
            'limit': 30,
          }),
          Produk.fromJson);

  Future<Produk> byBarcode(String code) async =>
      Produk.fromJson(await apiGet('/produk/barcode/$code'));

  Future<List<Kategori>> kategori() async =>
      apiList<Kategori>(await apiGet('/kategori'), Kategori.fromJson);

  Future<List<Satuan>> satuan() async =>
      apiList<Satuan>(await apiGet('/satuan'), Satuan.fromJson);

  Future<Produk> produkDetail(int id) async => Produk.fromJson(await apiGet('/produk/$id'));

  Future<Produk> create({
    required String nama,
    required int idKategori,
    required int hargaBeli,
    required int hargaJual,
    int stok = 0,
    String? barcode,
    int? idSatuan,
    String? fotoPath,
  }) async =>
      Produk.fromJson(await apiPostMultipart('/produk', {
        'nama': nama,
        'id_kategori': idKategori,
        'harga_beli': hargaBeli,
        'harga_jual': hargaJual,
        'stok': stok,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        if (idSatuan != null) 'id_satuan': idSatuan,
      }, filePath: fotoPath));

  Future<Produk> update(
    int id, {
    required String nama,
    required int idKategori,
    required int hargaBeli,
    required int hargaJual,
    String? barcode,
    int? idSatuan,
    String? fotoPath,
  }) async =>
      Produk.fromJson(await apiPutMultipart('/produk/$id', {
        'nama': nama,
        'id_kategori': idKategori,
        'harga_beli': hargaBeli,
        'harga_jual': hargaJual,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        'id_satuan': idSatuan,
      }, filePath: fotoPath));

  Future<void> delete(Produk item) async => apiDelete('/produk/${item.id}');

  // -- Varian / modifier groups (dipakai VarianSheet) --
  Future<List<ModifierGroup>> modifierGroups() async =>
      apiList<ModifierGroup>(await apiGet('/modifier/groups'), ModifierGroup.fromJson);

  Future<List<ModifierGroup>> modifierFor(int produkId) async =>
      apiList<ModifierGroup>(await apiGet('/modifier/produk/$produkId'), ModifierGroup.fromJson);

  Future<void> setProductModifierGroups(int produkId, List<int> groupIds) async =>
      apiPut('/modifier/produk/$produkId', {'group_ids': groupIds});
}
