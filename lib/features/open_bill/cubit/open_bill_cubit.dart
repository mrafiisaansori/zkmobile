import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../shared/models/models.dart';
import '../data/open_bill_repository.dart';

class OpenBillState extends Equatable {
  final String status;
  final String search;
  final bool loading;
  final List<OpenBill> data;
  final List<QueuedSale> pendingBills;
  final String? error;
  const OpenBillState({
    this.status = 'OPEN',
    this.search = '',
    this.loading = true,
    this.data = const [],
    this.pendingBills = const [],
    this.error,
  });

  OpenBillState copyWith({
    String? status,
    String? search,
    bool? loading,
    List<OpenBill>? data,
    List<QueuedSale>? pendingBills,
    String? error,
  }) =>
      OpenBillState(
        status: status ?? this.status,
        search: search ?? this.search,
        loading: loading ?? this.loading,
        data: data ?? this.data,
        pendingBills: pendingBills ?? this.pendingBills,
        error: error, // tidak fallback — tiap emit baru "bersih".
      );

  @override
  List<Object?> get props => [status, search, loading, data, pendingBills, error];
}

// Padanan OpenBillPageState lama. Bill baru yang dibuat offline belum punya
// ID server — belum bisa dibuka/dibayar/dibatalkan sampai berhasil
// disinkron, tapi tetap ditampilkan di tab Aktif lewat `pendingBills` supaya
// tidak "hilang" dari pandangan kasir.
class OpenBillCubit extends Cubit<OpenBillState> {
  final OpenBillRepository _repo;
  Timer? _debounce;

  OpenBillCubit({OpenBillRepository? repository})
      : _repo = repository ?? OpenBillRepository(),
        super(const OpenBillState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final q = await getOfflineQueue();
    final pending = q.where((e) => e.endpoint == '/open-bill').toList();
    try {
      final data = await _repo.list(status: state.status, search: state.search);
      emit(state.copyWith(loading: false, data: data, pendingBills: pending));
    } catch (e) {
      emit(state.copyWith(loading: false, pendingBills: pending, error: _message(e)));
    }
  }

  Future<void> refresh() => load();

  void setStatus(String status) {
    if (status == state.status) return;
    emit(state.copyWith(status: status));
    load();
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(search: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<OpenBill> openBillDetail(int id) => _repo.detail(id);

  Future<bool> cancelBill(int id) async {
    try {
      await _repo.cancel(id);
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(error: _message(e)));
      return false;
    }
  }

  Future<void> removePending(String localId) async {
    await removeFromQueue(localId);
    await load();
  }

  String _message(Object e) =>
      e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e');

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
