import '../../../core/network/api_client.dart';

// Status sesi kasir dipakai buat titik indikator "Sesi aktif/tidak aktif" di
// sidebar tablet dan buat ShellCubit tahu kapan harus refresh setelah pindah
// tab — padanan Api.shiftActive() lama.
class ShellRepository {
  Future<bool> shiftActive() async {
    try {
      return await apiGet('/kas-shift/active') != null;
    } catch (_) {
      return true; // gagal cek jangan sampai menghalangi kasir
    }
  }
}
