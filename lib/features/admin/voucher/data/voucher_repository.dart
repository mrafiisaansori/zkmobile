import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.vouchers/createVoucher/updateVoucher/deleteVoucher di
// lib/api.dart lama. GET /voucher tidak mendukung search/pagination server
// side (persis seperti UI lama yang tanpa search field) — fetchPage cukup
// balikin daftar penuh di halaman 1 dan kosong di halaman berikutnya supaya
// tetap cocok dengan kontrak ListCubit<T>.
class VoucherRepository {
  Future<List<Voucher>> fetchPage({String? search, int page = 1}) async {
    if (page > 1) return [];
    return apiList(await apiGet('/voucher'), Voucher.fromJson);
  }

  Future<Voucher> create(Map<String, dynamic> data) async =>
      Voucher.fromJson(await apiPost('/voucher', data));

  Future<Voucher> update(int id, Map<String, dynamic> data) async =>
      Voucher.fromJson(await apiPut('/voucher/$id', data));

  Future<void> delete(Voucher item) => apiDelete('/voucher/${item.id}');
}
