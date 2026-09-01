import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.produk/adjustStock di lib/api.dart lama. Daftar produk dipakai
// ulang dari endpoint /produk (limit 30, sama seperti stok opname di web
// yang cuma modal "Sesuaikan" di atas list produk) — bukan entity tersendiri.
class StokRepository {
  static const pageSize = 30;

  Future<List<Produk>> fetchPage({String? search, int page = 1}) async => apiList(
      await apiGet('/produk', {
        'search': (search ?? '').isEmpty ? null : search,
        'category_id': 'all',
        'page': page,
        'limit': pageSize,
      }),
      Produk.fromJson);

  Future<void> adjustStock(int idProduk, int jenis, int qty, {String? keterangan}) async =>
      apiPost('/produk/$idProduk/stok', {
        'jenis': jenis, // 1 = tambah (masuk), 2 = kurangi (keluar)
        'qty': qty,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      });
}
