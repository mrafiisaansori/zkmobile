import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../data/riwayat_repository.dart';

// Padanan _RiwayatPageState lama. Bespoke (bukan ListCubit<T>) karena
// sumbernya bukan "search+page", tapi filter tanggal-tunggal atau rentang
// tanggal — tidak cocok dengan kontrak fetchPage(search, page) generik.
class RiwayatState extends Equatable {
  final bool rangeMode;
  final DateTime tanggal;
  final DateTimeRange range;
  final List<Penjualan> data;
  final bool loading;
  final String? error;

  RiwayatState({
    this.rangeMode = false,
    DateTime? tanggal,
    DateTimeRange? range,
    this.data = const [],
    this.loading = true,
    this.error,
  })  : tanggal = tanggal ?? DateTime.now(),
        range = range ??
            DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 6)),
                end: DateTime.now());

  RiwayatState copyWith({
    bool? rangeMode,
    DateTime? tanggal,
    DateTimeRange? range,
    List<Penjualan>? data,
    bool? loading,
    String? error,
  }) =>
      RiwayatState(
        rangeMode: rangeMode ?? this.rangeMode,
        tanggal: tanggal ?? this.tanggal,
        range: range ?? this.range,
        data: data ?? this.data,
        loading: loading ?? this.loading,
        error: error, // tidak fallback — tiap emit baru "bersih".
      );

  int get total => data.fold(0, (s, p) => s + p.total);

  bool get isToday {
    final now = DateTime.now();
    return tanggal.year == now.year && tanggal.month == now.month && tanggal.day == now.day;
  }

  @override
  List<Object?> get props => [rangeMode, tanggal, range, data, loading, error];
}

class RiwayatCubit extends Cubit<RiwayatState> {
  final RiwayatRepository _repo;
  RiwayatCubit({RiwayatRepository? repository})
      : _repo = repository ?? RiwayatRepository(),
        super(RiwayatState());

  static String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final dari = state.rangeMode ? _iso(state.range.start) : _iso(state.tanggal);
      final sampai = state.rangeMode ? _iso(state.range.end) : _iso(state.tanggal);
      final data = await _repo.list(dari: dari, sampai: sampai);
      emit(state.copyWith(loading: false, data: data));
    } catch (e) {
      emit(state.copyWith(loading: false, error: _message(e)));
    }
  }

  void setMode(bool range) {
    if (range == state.rangeMode) return;
    emit(state.copyWith(rangeMode: range));
    load();
  }

  void setTanggal(DateTime d) {
    emit(state.copyWith(tanggal: d));
    load();
  }

  void setRange(DateTimeRange r) {
    emit(state.copyWith(range: r));
    load();
  }

  void resetToToday() {
    emit(state.copyWith(tanggal: DateTime.now()));
    load();
  }

  String _message(Object e) =>
      e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e');
}
