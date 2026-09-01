import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Bungkus endpoint /kategori — padanan bagian kategori di lib/api.dart lama.
// fetchPage() mengabaikan search/page (backend tidak mendukungnya untuk
// endpoint ini, sama seperti Api.kategori() lama yang selalu ambil semua).
class KategoriRepository {
  Future<List<Kategori>> fetchPage({String? search, int page = 1}) async =>
      apiList<Kategori>(await apiGet('/kategori'), Kategori.fromJson);

  Future<Kategori> create(String deskripsi) async =>
      Kategori.fromJson(await apiPost('/kategori', {'deskripsi': deskripsi}));

  Future<Kategori> update(int id, String deskripsi) async =>
      Kategori.fromJson(await apiPut('/kategori/$id', {'deskripsi': deskripsi}));

  Future<void> delete(Kategori item) async => apiDelete('/kategori/${item.id}');
}
