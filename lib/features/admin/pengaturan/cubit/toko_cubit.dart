import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';

enum TokoStatus { loading, ready, error }

class TokoState extends Equatable {
  final TokoStatus status;
  final bool saving, uploading;
  final String nama, alamat, noTelp, email, website;
  final String? logoUrl;
  final String? error;
  const TokoState({
    this.status = TokoStatus.loading,
    this.saving = false,
    this.uploading = false,
    this.nama = '',
    this.alamat = '',
    this.noTelp = '',
    this.email = '',
    this.website = '',
    this.logoUrl,
    this.error,
  });

  TokoState copyWith({
    TokoStatus? status,
    bool? saving,
    bool? uploading,
    String? nama,
    String? alamat,
    String? noTelp,
    String? email,
    String? website,
    String? logoUrl,
    String? error,
  }) =>
      TokoState(
        status: status ?? this.status,
        saving: saving ?? this.saving,
        uploading: uploading ?? this.uploading,
        nama: nama ?? this.nama,
        alamat: alamat ?? this.alamat,
        noTelp: noTelp ?? this.noTelp,
        email: email ?? this.email,
        website: website ?? this.website,
        logoUrl: logoUrl ?? this.logoUrl,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, saving, uploading, nama, alamat, noTelp, email, website, logoUrl, error];
}

// Padanan _TokoTabState lama (Api.identitas/updateIdentitas/uploadIdentitasLogo)
// — thin bespoke cubit, bukan FormSubmitCubit generik, karena tab ini punya
// dua aksi async independen (simpan form + unggah logo) yang butuh flag
// loading terpisah (saving vs uploading) sekaligus data awal buat diisi ke
// TextEditingController di widget.
class TokoCubit extends Cubit<TokoState> {
  TokoCubit() : super(const TokoState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: TokoStatus.loading));
    try {
      final d = await apiGet('/identitas') as Map<String, dynamic>;
      emit(state.copyWith(
        status: TokoStatus.ready,
        nama: '${d['NAMA'] ?? ''}',
        alamat: '${d['ALAMAT'] ?? ''}',
        noTelp: '${d['NO_TELP'] ?? ''}',
        email: '${d['EMAIL'] ?? ''}',
        website: '${d['WEBSITE'] ?? ''}',
        logoUrl: d['LOGO_URL'] as String?,
      ));
    } catch (e) {
      final msg = isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e';
      emit(state.copyWith(status: TokoStatus.error, error: msg));
    }
  }

  Future<void> save({
    required String nama,
    required String alamat,
    required String noTelp,
    required String email,
    required String website,
  }) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      await apiPut('/identitas', {
        'nama': nama,
        'alamat': alamat,
        'no_telp': noTelp,
        'email': email,
        'website': website,
      });
      emit(state.copyWith(saving: false));
    } catch (e) {
      emit(state.copyWith(saving: false));
      rethrow;
    }
  }

  Future<void> uploadLogo(String filePath) async {
    emit(state.copyWith(uploading: true, error: null));
    try {
      final d = await apiPostMultipart('/identitas/logo', {}, filePath: filePath, fileField: 'logo')
          as Map<String, dynamic>;
      emit(state.copyWith(uploading: false, logoUrl: d['LOGO_URL'] as String?));
    } catch (e) {
      emit(state.copyWith(uploading: false));
      rethrow;
    }
  }
}
