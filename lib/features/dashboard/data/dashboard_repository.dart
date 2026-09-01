import '../../../core/network/api_client.dart';

// Padanan Api.shiftActive()/Api.rekapHariIni() lama, dipakai oleh dashboard
// kasir (ringkasan hari ini + status sesi).
class DashboardRepository {
  Future<bool> shiftActive() async {
    try {
      return await apiGet('/kas-shift/active') != null;
    } catch (_) {
      return true; // gagal cek jangan sampai menghalangi kasir
    }
  }

  Future<Map<String, dynamic>> rekapHariIni(int idUser, String hari) async {
    final d = await apiGet('/laporan/penjualan', {
      'tanggal_awal': hari,
      'tanggal_akhir': hari,
      'id_user': idUser,
      'status': 1,
      'page': 1,
      'limit': 8,
    });
    return (d as Map<String, dynamic>?) ?? {};
  }
}
