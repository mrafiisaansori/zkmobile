import 'package:equatable/equatable.dart';
import '../../../../core/theme/dates.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';
import '../data/laporan_closing_repository.dart';

class LaporanClosingState extends Equatable {
  final DateTime tanggal;
  final DailyReport? report;
  final bool loading;
  final String? error;
  const LaporanClosingState({required this.tanggal, this.report, this.loading = true, this.error});

  LaporanClosingState copyWith(
          {DateTime? tanggal, DailyReport? report, bool? loading, String? error}) =>
      LaporanClosingState(
        tanggal: tanggal ?? this.tanggal,
        report: report ?? this.report,
        loading: loading ?? this.loading,
        error: error,
      );

  @override
  List<Object?> get props => [tanggal, report, loading, error];
}

// Padanan _AdminClosingPageState lama — rekap sesi kas SELURUH kasir per hari
// (beda dari features/closing/ yang dipakai KASIR untuk sesi miliknya sendiri).
class LaporanClosingCubit extends Cubit<LaporanClosingState> {
  final LaporanClosingRepository repo;
  LaporanClosingCubit(this.repo) : super(LaporanClosingState(tanggal: DateTime.now())) {
    load();
  }


  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final r = await repo.closingReportDaily(isoDate(state.tanggal));
      emit(state.copyWith(report: r, loading: false));
    } catch (e) {
      final msg = isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e';
      emit(state.copyWith(loading: false, error: msg));
    }
  }

  void setTanggal(DateTime d) {
    emit(state.copyWith(tanggal: d));
    load();
  }
}
