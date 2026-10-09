import 'package:equatable/equatable.dart';
import '../../../../core/theme/dates.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../../../../shared/models/models.dart';
import '../data/keuangan_repository.dart';

enum KeuanganStatus { loading, ready, error }

class KeuanganState extends Equatable {
  final KeuanganStatus status;
  final DateTimeRange range;
  final LaporanPenjualan? penjualan;
  final LaporanPendapatan? pendapatan;
  final RekapLaporan? rekap;
  final String? error;
  KeuanganState({
    this.status = KeuanganStatus.loading,
    DateTimeRange? range,
    this.penjualan,
    this.pendapatan,
    this.rekap,
    this.error,
  }) : range = range ??
            DateTimeRange(start: DateTime.now().subtract(const Duration(days: 6)), end: DateTime.now());

  KeuanganState copyWith({
    KeuanganStatus? status,
    DateTimeRange? range,
    LaporanPenjualan? penjualan,
    LaporanPendapatan? pendapatan,
    RekapLaporan? rekap,
    String? error,
  }) =>
      KeuanganState(
        status: status ?? this.status,
        range: range ?? this.range,
        penjualan: penjualan ?? this.penjualan,
        pendapatan: pendapatan ?? this.pendapatan,
        rekap: rekap ?? this.rekap,
        error: error,
      );

  @override
  List<Object?> get props => [status, range, penjualan, pendapatan, rekap, error];
}

// Padanan _AdminKeuanganPageState lama: laporan penjualan/pendapatan/rekap
// per rentang tanggal (default 7 hari terakhir). Rekap null berarti plan
// FREE (backend 403, dibungkus opsional oleh repository) — widget yang
// tampilkan banner upsell PRO/BUSINESS, bukan cubit ini.
class KeuanganCubit extends Cubit<KeuanganState> {
  final KeuanganRepository _repo;
  KeuanganCubit([KeuanganRepository? repo])
      : _repo = repo ?? KeuanganRepository(),
        super(KeuanganState()) {
    load();
  }


  Future<void> load() async {
    emit(state.copyWith(status: KeuanganStatus.loading, error: null));
    try {
      final dari = isoDate(state.range.start), sampai = isoDate(state.range.end);
      final results = await Future.wait([
        _repo.penjualan(dari, sampai),
        _repo.pendapatan(dari, sampai),
        _repo.rekap(dari, sampai),
      ]);
      emit(state.copyWith(
        status: KeuanganStatus.ready,
        penjualan: results[0] as LaporanPenjualan,
        pendapatan: results[1] as LaporanPendapatan,
        rekap: results[2] as RekapLaporan?,
      ));
    } catch (e) {
      emit(state.copyWith(status: KeuanganStatus.error, error: '$e'));
    }
  }

  Future<void> setRange(DateTimeRange range) async {
    emit(state.copyWith(range: range));
    await load();
  }
}
