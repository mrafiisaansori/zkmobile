import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';
import '../data/langganan_repository.dart';

enum LanggananStatus { loading, ready, error }

class LanggananState extends Equatable {
  final LanggananStatus status;
  final Billing? billing;
  final SubscriptionSetting? setting;
  final bool paying;
  final String? error;
  const LanggananState({
    this.status = LanggananStatus.loading,
    this.billing,
    this.setting,
    this.paying = false,
    this.error,
  });

  LanggananState copyWith({
    LanggananStatus? status,
    Billing? billing,
    SubscriptionSetting? setting,
    bool? paying,
    String? error,
  }) =>
      LanggananState(
        status: status ?? this.status,
        billing: billing ?? this.billing,
        setting: setting ?? this.setting,
        paying: paying ?? this.paying,
        error: error,
      );

  @override
  List<Object?> get props => [status, billing, setting, paying, error];
}

// Padanan _AdminLanggananPageState lama: Future.wait([subscriptionBilling,
// subscriptionSetting]) buat status/paket harga, lalu createSubscriptionPayment
// buat mulai pembayaran Midtrans (widget yang navigasi ke MidtransPaymentPage
// dan panggil load() lagi setelah kembali — cubit ini tidak tahu soal WebView).
class LanggananCubit extends Cubit<LanggananState> {
  final LanggananRepository _repo;
  LanggananCubit([LanggananRepository? repo])
      : _repo = repo ?? LanggananRepository(),
        super(const LanggananState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: LanggananStatus.loading));
    try {
      final results = await Future.wait([_repo.billing(), _repo.setting()]);
      emit(state.copyWith(
        status: LanggananStatus.ready,
        billing: results[0] as Billing,
        setting: results[1] as SubscriptionSetting,
      ));
    } catch (e) {
      final msg = isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e';
      emit(state.copyWith(status: LanggananStatus.error, error: msg));
    }
  }

  Future<SubscriptionPayment> upgrade(String paket) async {
    emit(state.copyWith(paying: true));
    try {
      final payment = await _repo.createPayment('PRO', paket);
      emit(state.copyWith(paying: false));
      return payment;
    } catch (e) {
      emit(state.copyWith(paying: false));
      rethrow;
    }
  }
}
