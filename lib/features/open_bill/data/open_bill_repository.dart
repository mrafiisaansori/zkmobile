import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

// Padanan bagian Api lama yang dipakai OpenBillPage (list/detail/cancel).
// Pembuatan/pembayaran bill dilakukan dari POS (fitur lain), jadi tidak
// diduplikasi di sini.
class OpenBillRepository {
  Future<List<OpenBill>> list({String status = 'OPEN', String? search}) async =>
      apiList(
          await apiGet('/open-bill', {
            'status': status,
            'search': (search ?? '').isEmpty ? null : search,
            'limit': 25,
          }),
          OpenBill.fromJson);

  Future<OpenBill> detail(int id) async => OpenBill.fromJson(await apiGet('/open-bill/$id'));

  Future<void> cancel(int id) async => apiPost('/open-bill/$id/cancel');
}
