import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

enum PembayaranStatus { loading, ready, error }

class PembayaranState extends Equatable {
  final PembayaranStatus status;
  final bool saving;
  final String merchantName, nmid;
  final bool isActive;
  final String? imageUrl;
  final String? error;
  const PembayaranState({
    this.status = PembayaranStatus.loading,
    this.saving = false,
    this.merchantName = '',
    this.nmid = '',
    this.isActive = false,
    this.imageUrl,
    this.error,
  });

  PembayaranState copyWith({
    PembayaranStatus? status,
    bool? saving,
    String? merchantName,
    String? nmid,
    bool? isActive,
    String? imageUrl,
    String? error,
  }) =>
      PembayaranState(
        status: status ?? this.status,
        saving: saving ?? this.saving,
        merchantName: merchantName ?? this.merchantName,
        nmid: nmid ?? this.nmid,
        isActive: isActive ?? this.isActive,
        imageUrl: imageUrl ?? this.imageUrl,
        error: error,
      );

  @override
  List<Object?> get props => [status, saving, merchantName, nmid, isActive, imageUrl, error];
}

// Padanan _PembayaranTabState lama (Api.qris/updateQris) — QRIS statis,
// pelanggan scan lalu kasir konfirmasi manual. Path gambar yang baru dipilih
// tapi belum diunggah (_newImagePath di versi lama) tetap jadi state lokal
// widget, bukan concern cubit ini — sama seperti TextEditingController.
class PembayaranCubit extends Cubit<PembayaranState> {
  PembayaranCubit() : super(const PembayaranState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: PembayaranStatus.loading));
    try {
      final q = await apiOpsional(() async {
        final d = await apiGet('/qris');
        return Qris.fromJson(d);
      });
      if (q != null) {
        emit(state.copyWith(
          status: PembayaranStatus.ready,
          merchantName: q.merchantName ?? '',
          nmid: q.nmid ?? '',
          isActive: q.isActive,
          imageUrl: q.imageUrl,
        ));
      } else {
        emit(state.copyWith(status: PembayaranStatus.ready));
      }
    } catch (e) {
      final msg = isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e';
      emit(state.copyWith(status: PembayaranStatus.error, error: msg));
    }
  }

  void setActive(bool v) => emit(state.copyWith(isActive: v));

  Future<void> save({
    required String merchantName,
    required String nmid,
    String? filePath,
  }) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      final q = Qris.fromJson(await apiPutMultipart('/qris', {
        'merchant_name': merchantName,
        'nmid': nmid,
        'is_active': state.isActive,
      }, filePath: filePath, fileField: 'image'));
      emit(state.copyWith(
          saving: false,
          merchantName: merchantName,
          nmid: nmid,
          imageUrl: q.imageUrl));
    } catch (e) {
      emit(state.copyWith(saving: false));
      rethrow;
    }
  }
}
