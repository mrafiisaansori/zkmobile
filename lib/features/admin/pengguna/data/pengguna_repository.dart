import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Bungkus endpoint /pengguna — padanan bagian pengguna di lib/api.dart lama.
class PenggunaRepository {
  Future<List<Pengguna>> fetchPage({String? search, int page = 1}) async =>
      apiList<Pengguna>(await apiGet('/pengguna'), Pengguna.fromJson);

  Future<Pengguna> create(Map<String, dynamic> data) async =>
      Pengguna.fromJson(await apiPost('/pengguna', data));

  Future<Pengguna> update(int id, Map<String, dynamic> data) async =>
      Pengguna.fromJson(await apiPut('/pengguna/$id', data));

  Future<void> delete(Pengguna item) async => apiDelete('/pengguna/${item.id}');

  Future<Map<String, dynamic>> resetPassword(int id) async =>
      await apiPost('/pengguna/$id/reset-password') as Map<String, dynamic>;
}
