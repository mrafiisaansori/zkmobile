import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Bungkus endpoint /satuan — padanan bagian satuan di lib/api.dart lama.
class SatuanRepository {
  Future<List<Satuan>> fetchPage({String? search, int page = 1}) async =>
      apiList<Satuan>(await apiGet('/satuan'), Satuan.fromJson);

  Future<Satuan> create(String nama) async =>
      Satuan.fromJson(await apiPost('/satuan', {'nama': nama}));

  Future<Satuan> update(int id, String nama) async =>
      Satuan.fromJson(await apiPut('/satuan/$id', {'nama': nama}));

  Future<void> delete(Satuan item) async => apiDelete('/satuan/${item.id}');
}
