import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.pembelian/pembelianDetail/createPembelian/updatePembelian/
// deletePembelian/selesaikanPembelian di lib/api.dart lama. GET /pembelian
// tidak punya parameter `page` (limit 25 tetap, tanpa infinite-scroll) —
// persis seperti UI lama yang tidak memuat halaman berikutnya. fetchPage
// tetap mengikuti kontrak ListCubit<T> dengan membalas [] di halaman > 1.
class PembelianRepository {
  Future<List<Pembelian>> fetchPage({String? search, int page = 1, int? status}) async {
    if (page > 1) return [];
    return apiList(
        await apiGet('/pembelian', {
          'search': (search ?? '').isEmpty ? null : search,
          'status': status,
          'limit': 25,
        }),
        Pembelian.fromJson);
  }

  Future<Pembelian> detail(int id) async => Pembelian.fromJson(await apiGet('/pembelian/$id'));

  Future<int> create(Map<String, dynamic> data) async {
    final d = await apiPost('/pembelian', data) as Map<String, dynamic>;
    return (d['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> update(int id, Map<String, dynamic> data) => apiPut('/pembelian/$id', data);

  Future<void> delete(Pembelian item) => apiDelete('/pembelian/${item.id}');

  Future<void> selesaikan(int id) => apiPost('/pembelian/$id/selesaikan');

  Future<List<Supplier>> suppliers() async => apiList(
      await apiGet('/supplier', {'search': null, 'limit': 100}), Supplier.fromJson);
}
