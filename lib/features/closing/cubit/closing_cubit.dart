import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../data/closing_repository.dart';

// Padanan _ClosingPageState lama: status sesi kasir aktif (`shift`) + hasil
// tutup kasir terakhir (`result`, buat kartu "Kasir Ditutup" sebelum user
// buka lagi). Cuma satu dari keduanya yang tampil sekaligus.
class ClosingState extends Equatable {
  final bool loading;
  final Map<String, dynamic>? shift;
  final Map<String, dynamic>? result;
  final String? error;
  const ClosingState({this.loading = true, this.shift, this.result, this.error});

  @override
  List<Object?> get props => [loading, shift, result, error];
}

class ClosingCubit extends Cubit<ClosingState> {
  final ClosingRepository _repo;
  ClosingCubit({ClosingRepository? repository})
      : _repo = repository ?? ClosingRepository(),
        super(const ClosingState());

  Future<void> load() async {
    emit(ClosingState(loading: true, shift: state.shift, result: state.result));
    try {
      final s = await _repo.activeShift();
      emit(ClosingState(loading: false, shift: s, result: state.result));
    } catch (e) {
      emit(ClosingState(
          loading: false, shift: state.shift, result: state.result, error: _message(e)));
    }
  }

  Future<void> refresh() => load();

  // Dipanggil setelah BukaSesiSheet berhasil buka sesi — bersihkan kartu
  // hasil tutup kasir sebelumnya, lalu muat ulang status sesi aktif.
  Future<void> afterBukaKasir() async {
    emit(ClosingState(loading: true, shift: state.shift));
    try {
      final s = await _repo.activeShift();
      emit(ClosingState(loading: false, shift: s));
    } catch (e) {
      emit(ClosingState(loading: false, error: _message(e)));
    }
  }

  Future<void> afterMutasi() => load();

  Future<Map<String, dynamic>> closePreview(int shiftId) => _repo.closePreview(shiftId);

  // Dipanggil setelah CloseKasirSheet berhasil menutup kasir.
  void setClosed(Map<String, dynamic> result) {
    emit(ClosingState(loading: false, result: result));
  }

  String _message(Object e) =>
      e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e');
}
