import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.closingReportDaily dari lib/api.dart lama.
class LaporanClosingRepository {
  Future<DailyReport> closingReportDaily(String tanggal) async =>
      DailyReport.fromJson(
          await apiGet('/kas-shift/report/daily', {'tanggal': tanggal}) as Map<String, dynamic>);
}
