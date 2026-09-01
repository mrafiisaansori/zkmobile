import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/models.dart';
import '../data/admin_dashboard_repository.dart';

enum AdminDashboardStatus { loading, ready, error }

class AdminDashboardState extends Equatable {
  final AdminDashboardStatus status;
  final DashboardSummary? summary;
  final List<ChartBulan> chart;
  final String? error;
  const AdminDashboardState({
    this.status = AdminDashboardStatus.loading,
    this.summary,
    this.chart = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, summary, chart, error];
}

// Padanan _AdminDashboardPageState lama: Future.wait([dashboardSummary,
// dashboardChart]) lalu dituang ke state loading/ready/error. Selalu bikin
// state baru (bukan copyWith parsial) supaya "pull to refresh" balik
// menampilkan spinner penuh dulu — sama persis seperti versi setState lama
// yang set `_loading = true` tanpa menyimpan data lama saat refresh.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminDashboardRepository _repo;
  AdminDashboardCubit([AdminDashboardRepository? repo])
      : _repo = repo ?? AdminDashboardRepository(),
        super(const AdminDashboardState()) {
    load();
  }

  Future<void> load() async {
    emit(const AdminDashboardState(status: AdminDashboardStatus.loading));
    try {
      final results = await Future.wait([_repo.summary(), _repo.chart(DateTime.now().year)]);
      emit(AdminDashboardState(
        status: AdminDashboardStatus.ready,
        summary: results[0] as DashboardSummary,
        chart: results[1] as List<ChartBulan>,
      ));
    } catch (e) {
      emit(AdminDashboardState(status: AdminDashboardStatus.error, error: '$e'));
    }
  }
}
