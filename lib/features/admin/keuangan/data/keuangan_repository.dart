import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.laporanPenjualan/laporanPendapatan/laporanRekap (lib/api.dart
// lama) — cuma membungkus request/response mentah, tanpa logika bisnis.
class KeuanganRepository {
  Future<LaporanPenjualan> penjualan(String dari, String sampai) async =>
      LaporanPenjualan.fromJson(await apiGet('/laporan/penjualan', {
        'tanggal_awal': dari,
        'tanggal_akhir': sampai,
        'id_user': 'all',
        'status': 1,
      }) as Map<String, dynamic>);

  Future<LaporanPendapatan> pendapatan(String dari, String sampai) async =>
      LaporanPendapatan.fromJson(await apiGet(
          '/laporan/pendapatan', {'tanggal_awal': dari, 'tanggal_akhir': sampai, 'status': 1}) as Map<String, dynamic>);

  // Rekap lengkap cuma untuk plan PRO/BUSINESS — backend balas 403 di FREE,
  // jadi dibungkus opsional sama seperti tax()/qris().
  Future<RekapLaporan?> rekap(String dari, String sampai) async => apiOpsional(() async {
        final d = await apiGet('/laporan/rekap',
            {'tanggal_awal': dari, 'tanggal_akhir': sampai, 'status': 1, 'top_limit': 20});
        return RekapLaporan.fromJson(d as Map<String, dynamic>);
      });
}
