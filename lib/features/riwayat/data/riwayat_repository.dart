import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

// Padanan bagian Api lama dipakai RiwayatPage & RiwayatDetailPage.
class RiwayatRepository {
  Future<List<Penjualan>> list(
          {required String dari, required String sampai, int page = 1}) async =>
      apiList(
          await apiGet('/penjualan', {
            'tanggal_awal': dari,
            'tanggal_akhir': sampai,
            'status': 1,
            'page': page,
            'limit': 25,
          }),
          Penjualan.fromJson);

  Future<Penjualan> detail(int id) async =>
      Penjualan.fromJson(await apiGet('/penjualan/$id'));

  Future<bool> kirimWA(int id, String nomor) async {
    final d = await apiPost('/penjualan/$id/kirim-wa', {'nomor': nomor})
        as Map<String, dynamic>;
    return d['terkirim'] == true;
  }
}
