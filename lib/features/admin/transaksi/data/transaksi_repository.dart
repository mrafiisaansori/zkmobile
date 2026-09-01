import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.penjualanList/penjualanDetail/voidPenjualan di lib/api.dart
// lama — daftar transaksi SELURUH kasir (beda dari riwayat kasir yang
// scope-nya transaksi sendiri saja), dipakai halaman Laporan Transaksi admin.
class TransaksiRepository {
  Future<List<Penjualan>> list(
          {required String dari, required String sampai, int status = 1, int page = 1}) async =>
      apiList(
          await apiGet('/penjualan', {
            'tanggal_awal': dari,
            'tanggal_akhir': sampai,
            'status': status,
            'page': page,
            'limit': 25,
          }),
          Penjualan.fromJson);

  Future<Penjualan> detail(int id) async => Penjualan.fromJson(await apiGet('/penjualan/$id'));

  Future<void> voidTx(int id) => apiPost('/penjualan/$id/void');
}
