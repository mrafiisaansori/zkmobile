import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

enum PajakStatus { loading, ready, error }

class PajakState extends Equatable {
  final PajakStatus status;
  final bool saving;
  final bool ppnOn, serviceOn;
  final num ppnPersen, servicePersen;
  final String? error;
  const PajakState({
    this.status = PajakStatus.loading,
    this.saving = false,
    this.ppnOn = false,
    this.serviceOn = false,
    this.ppnPersen = 0,
    this.servicePersen = 0,
    this.error,
  });

  PajakState copyWith({
    PajakStatus? status,
    bool? saving,
    bool? ppnOn,
    bool? serviceOn,
    num? ppnPersen,
    num? servicePersen,
    String? error,
  }) =>
      PajakState(
        status: status ?? this.status,
        saving: saving ?? this.saving,
        ppnOn: ppnOn ?? this.ppnOn,
        serviceOn: serviceOn ?? this.serviceOn,
        ppnPersen: ppnPersen ?? this.ppnPersen,
        servicePersen: servicePersen ?? this.servicePersen,
        error: error,
      );

  @override
  List<Object?> get props => [status, saving, ppnOn, serviceOn, ppnPersen, servicePersen, error];
}

// Padanan _PajakTabState lama (Api.tax/updateTax) — fitur PRO-only, jadi
// hanya panggil API kalau Session.isPro (sama seperti kondisi
// `if (Session.isPro) _load(); else _loading = false;` di versi setState).
// Widget yang membaca Session.isPro untuk menampilkan gerbang upgrade,
// bukan cubit ini — supaya cubit tetap murni state-machine data.
class PajakCubit extends Cubit<PajakState> {
  PajakCubit() : super(const PajakState()) {
    if (Session.isPro) {
      load();
    } else {
      emit(state.copyWith(status: PajakStatus.ready));
    }
  }

  Future<void> load() async {
    emit(state.copyWith(status: PajakStatus.loading));
    try {
      final t = await apiOpsional(() async {
        final d = await apiGet('/tax');
        return TaxSetting.fromJson(d);
      });
      if (t != null) {
        emit(state.copyWith(
          status: PajakStatus.ready,
          ppnOn: t.ppnOn,
          serviceOn: t.serviceOn,
          ppnPersen: t.ppnPersen,
          servicePersen: t.servicePersen,
        ));
      } else {
        emit(state.copyWith(status: PajakStatus.ready));
      }
    } catch (e) {
      final msg = isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e';
      emit(state.copyWith(status: PajakStatus.error, error: msg));
    }
  }

  void setPpnOn(bool v) => emit(state.copyWith(ppnOn: v));
  void setServiceOn(bool v) => emit(state.copyWith(serviceOn: v));

  Future<void> save({required num ppnPersen, required num servicePersen}) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      await apiPut('/tax', {
        'ppn_enabled': state.ppnOn,
        'ppn_persen': ppnPersen,
        'service_enabled': state.serviceOn,
        'service_persen': servicePersen,
      });
      emit(state.copyWith(saving: false, ppnPersen: ppnPersen, servicePersen: servicePersen));
    } catch (e) {
      emit(state.copyWith(saving: false));
      rethrow;
    }
  }
}
