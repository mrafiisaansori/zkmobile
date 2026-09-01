import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Bungkus endpoint /supplier — padanan bagian supplier di lib/api.dart lama.
class SupplierRepository {
  Future<List<Supplier>> fetchPage({String? search, int page = 1}) async =>
      apiList<Supplier>(
          await apiGet('/supplier', {
            'search': (search ?? '').isEmpty ? null : search,
            'limit': 100,
          }),
          Supplier.fromJson);

  Future<Supplier> create(Map<String, dynamic> data) async =>
      Supplier.fromJson(await apiPost('/supplier', data));

  Future<Supplier> update(int id, Map<String, dynamic> data) async =>
      Supplier.fromJson(await apiPut('/supplier/$id', data));

  Future<void> delete(Supplier item) async => apiDelete('/supplier/${item.id}');
}
