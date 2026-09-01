import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.retur/returDetail/createRetur/updateRetur/deleteRetur/
// selesaikanRetur/batalRetur di lib/api.dart lama. GET /retur tidak punya
// parameter `page` (limit 25 tetap) — sama seperti PembelianRepository,
// fetchPage tetap mengikuti kontrak ListCubit<T> dengan membalas [] di
// halaman > 1.
class ReturRepository {
  Future<List<Retur>> fetchPage({String? search, int page = 1, int? status}) async {
    if (page > 1) return [];
    return apiList(
        await apiGet('/retur', {
          'search': (search ?? '').isEmpty ? null : search,
          'status': status,
          'limit': 25,
        }),
        Retur.fromJson);
  }

  Future<Retur> detail(int id) async => Retur.fromJson(await apiGet('/retur/$id'));

  Future<int> create(Map<String, dynamic> data) async {
    final d = await apiPost('/retur', data) as Map<String, dynamic>;
    return (d['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> update(int id, Map<String, dynamic> data) => apiPut('/retur/$id', data);

  Future<void> delete(Retur item) => apiDelete('/retur/${item.id}');

  Future<void> selesaikan(int id) => apiPost('/retur/$id/selesaikan');

  Future<void> batal(int id) => apiPost('/retur/$id/batal');

  Future<List<Supplier>> suppliers() async => apiList(
      await apiGet('/supplier', {'search': null, 'limit': 100}), Supplier.fromJson);

  // Pembelian berstatus Selesai — opsi "Pembelian asal" di form retur
  // (padanan Api.pembelian(status: 1) yang dipakai admin_retur_form_page.dart lama).
  Future<List<Pembelian>> pembelianSelesai() async => apiList(
      await apiGet('/pembelian', {'search': null, 'status': 1, 'limit': 25}),
      Pembelian.fromJson);
}
