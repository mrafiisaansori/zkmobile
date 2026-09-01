import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.dashboardSummary/dashboardChart (lib/api.dart lama) — cuma
// membungkus request/response mentah, tanpa logika bisnis.
class AdminDashboardRepository {
  Future<DashboardSummary> summary() async =>
      DashboardSummary.fromJson(await apiGet('/dashboard/summary') as Map<String, dynamic>);

  Future<List<ChartBulan>> chart(int tahun) async {
    final r = await apiGet('/dashboard/chart', {'tahun': tahun}) as Map<String, dynamic>;
    return apiList(r['data'], ChartBulan.fromJson);
  }
}
