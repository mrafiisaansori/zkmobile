import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../data/dashboard_repository.dart';

class DashboardState extends Equatable {
  final bool loading;
  final int total, jumlah;
  final List<Penjualan> data;
  final bool shiftActive;
  final String? error;
  const DashboardState({
    this.loading = true,
    this.total = 0,
    this.jumlah = 0,
    this.data = const [],
    this.shiftActive = true,
    this.error,
  });

  DashboardState copyWith({
    bool? loading,
    int? total,
    int? jumlah,
    List<Penjualan>? data,
    bool? shiftActive,
    String? error,
  }) =>
      DashboardState(
        loading: loading ?? this.loading,
        total: total ?? this.total,
        jumlah: jumlah ?? this.jumlah,
        data: data ?? this.data,
        shiftActive: shiftActive ?? this.shiftActive,
        error: error, // tidak fallback ke this.error — tiap emit baru "bersih".
      );

  @override
  List<Object?> get props => [loading, total, jumlah, data, shiftActive, error];
}

// Padanan _DashboardPageState lama.
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repo;
  DashboardCubit({DashboardRepository? repository})
      : _repo = repository ?? DashboardRepository(),
        super(const DashboardState());

  String get _hariIni => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final aktif = await _repo.shiftActive();
    try {
      final r = await _repo.rekapHariIni(Session.user?.id ?? 0, _hariIni);
      emit(state.copyWith(
        loading: false,
        total: (r['total_dibayar'] as num?)?.toInt() ?? 0,
        jumlah: (r['jumlah_transaksi'] as num?)?.toInt() ?? 0,
        data: ((r['data'] as List?) ?? [])
            .map((e) => Penjualan.fromJson(e as Map<String, dynamic>))
            .toList(),
        shiftActive: aktif,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, shiftActive: aktif, error: _message(e)));
    }
  }

  String _message(Object e) =>
      e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e');
}
