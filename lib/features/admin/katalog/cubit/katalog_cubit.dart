import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../data/katalog_repository.dart';

enum KatalogStatus { loading, ready, error }

class KatalogState extends Equatable {
  final KatalogStatus status;
  final bool savingSlug, uploading;
  final String slug;
  final String? bannerUrl;
  final String? error;
  const KatalogState({
    this.status = KatalogStatus.loading,
    this.savingSlug = false,
    this.uploading = false,
    this.slug = '',
    this.bannerUrl,
    this.error,
  });

  KatalogState copyWith({
    KatalogStatus? status,
    bool? savingSlug,
    bool? uploading,
    String? slug,
    String? bannerUrl,
    String? error,
  }) =>
      KatalogState(
        status: status ?? this.status,
        savingSlug: savingSlug ?? this.savingSlug,
        uploading: uploading ?? this.uploading,
        slug: slug ?? this.slug,
        bannerUrl: bannerUrl ?? this.bannerUrl,
        error: error,
      );

  @override
  List<Object?> get props => [status, savingSlug, uploading, slug, bannerUrl, error];
}

// Padanan _AdminKatalogPageState lama (Api.merchantMe/updateMerchantSlug,
// Api.identitas/uploadIdentitasBanner) — thin bespoke cubit sama seperti
// TokoCubit, karena tab ini juga punya dua aksi async independen (simpan
// slug + unggah banner) yang butuh flag loading terpisah.
class KatalogCubit extends Cubit<KatalogState> {
  final KatalogRepository _repo;
  KatalogCubit([KatalogRepository? repo])
      : _repo = repo ?? KatalogRepository(),
        super(const KatalogState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: KatalogStatus.loading));
    try {
      final results = await Future.wait([_repo.merchantMe(), _repo.identitas()]);
      final merchant = results[0];
      final identitas = results[1];
      emit(state.copyWith(
        status: KatalogStatus.ready,
        slug: '${merchant['SLUG'] ?? ''}',
        bannerUrl: identitas['BANNER_URL'] as String?,
      ));
    } catch (e) {
      final msg = isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e';
      emit(state.copyWith(status: KatalogStatus.error, error: msg));
    }
  }

  Future<void> saveSlug(String slug) async {
    emit(state.copyWith(savingSlug: true, error: null));
    try {
      final m = await _repo.updateSlug(slug);
      emit(state.copyWith(savingSlug: false, slug: '${m['SLUG'] ?? ''}'));
    } catch (e) {
      emit(state.copyWith(savingSlug: false));
      rethrow;
    }
  }

  Future<void> uploadBanner(String filePath) async {
    emit(state.copyWith(uploading: true, error: null));
    try {
      final d = await _repo.uploadBanner(filePath);
      emit(state.copyWith(uploading: false, bannerUrl: d['BANNER_URL'] as String?));
    } catch (e) {
      emit(state.copyWith(uploading: false));
      rethrow;
    }
  }
}
