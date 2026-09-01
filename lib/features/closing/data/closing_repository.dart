import '../../../core/network/api_client.dart';

// Padanan bagian Api lama dipakai ClosingPage: status sesi kasir aktif,
// catat kas keluar/masuk, preview & eksekusi tutup kasir. Pembukaan sesi
// sendiri (openShift) dipakai lewat BukaSesiSheet di fitur pos/, jadi tidak
// diduplikasi di sini.
class ClosingRepository {
  Future<Map<String, dynamic>?> activeShift() async =>
      await apiGet('/kas-shift/active') as Map<String, dynamic>?;

  Future<void> mutasi(int shiftId, String tipe, int nominal, {String? keterangan}) async =>
      await apiPost('/kas-shift/$shiftId/mutasi', {
        'tipe': tipe,
        'nominal': nominal,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      });

  Future<Map<String, dynamic>> closePreview(int shiftId) async =>
      await apiGet('/kas-shift/$shiftId/close-preview') as Map<String, dynamic>;

  Future<Map<String, dynamic>> close(int shiftId, int actualCash, {String? catatan}) async =>
      await apiPost('/kas-shift/$shiftId/close', {
        'actual_cash': actualCash,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      }) as Map<String, dynamic>;
}
