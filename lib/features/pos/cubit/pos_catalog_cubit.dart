import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/catalog_cache.dart';
import '../../../shared/models/models.dart';
import '../data/pos_repository.dart';
import 'pos_catalog_state.dart';

// Padanan separuh "katalog" dari PosPageState lama: grid produk (load,
// search-debounce dipicu dari luar lewat parameter search, paginate,
// filter kategori), referensi (kategori/metode-bayar/pajak/qris), status
// sesi kasir, dan cache varian per produk (_modCache).
class PosCatalogCubit extends Cubit<PosCatalogState> {
  final PosRepository _repo;
  PosCatalogCubit({PosRepository? repository})
      : _repo = repository ?? PosRepository(),
        super(const PosCatalogState());

  // Cache varian per produk agar tidak request berulang (padanan modCache di
  // web) — bukan bagian dari state Equatable karena murni memoization
  // internal, bukan sesuatu yang perlu memicu rebuild UI.
  final Map<int, List<ModifierGroup>> _modCache = {};

  Future<void> loadRefs() async {
    final aktif = await _repo.shiftActive();
    if (!isClosed) emit(state.copyWith(shiftActive: aktif));
    try {
      final k = await _repo.kategori();
      final j = await _repo.jenisBayar();
      final t = await _repo.tax();
      final q = await _repo.qris();
      if (!isClosed) {
        emit(state.copyWith(kategori: k, jenisBayar: j, tax: t, clearTax: t == null, qris: q, clearQris: q == null));
      }
      // Simpan buat fallback offline — tidak perlu tunggu (fire and forget).
      cacheKategori(k);
      cacheJenisBayar(j);
      cacheTax(t);
    } catch (e) {
      // Referensi opsional gagal dimuat (mis. offline) — pakai cache lokal
      // biar metode pembayaran & kategori tetap ada saat koneksi putus.
      if (isNetworkError(e)) {
        final k = await readCachedKategori();
        final j = await readCachedJenisBayar();
        final t = await readCachedTax();
        if (!isClosed) {
          emit(state.copyWith(kategori: k, jenisBayar: j, tax: t, clearTax: t == null));
        }
      }
    }
  }

  Future<void> loadProduk({bool append = false, String? search, Object? categoryId}) async {
    final s = search ?? state.search;
    final kat = categoryId ?? state.activeKat;
    emit(state.copyWith(
      search: s,
      activeKat: kat,
      loading: append ? null : true,
      loadingMore: append ? true : null,
    ));
    // Fallback cache cuma masuk akal untuk daftar "Semua" halaman pertama —
    // hasil pencarian/kategori spesifik yang gagal dimuat tetap tampil kosong.
    final isDefaultView = !append && s.isEmpty && kat == 'all';
    try {
      final page = append ? state.page + 1 : 1;
      final res = await _repo.produk(search: s, categoryId: kat, page: page);
      if (isClosed) return;
      final produk = append
          ? [
              ...state.produk,
              ...res.where((p) => !state.produk.any((e) => e.id == p.id)),
            ]
          : res;
      emit(state.copyWith(
        produk: produk,
        page: page,
        lastPage: res.length < 30,
        loading: false,
        loadingMore: false,
      ));
      if (isDefaultView) cacheProduk(res);
      _prefetchModifiers(res);
    } catch (e) {
      if (isDefaultView && isNetworkError(e)) {
        final cached = await readCachedProduk();
        if (!isClosed) {
          emit(state.copyWith(
            produk: cached,
            page: 1,
            lastPage: true,
            loading: false,
            loadingMore: false,
            info: cached.isNotEmpty
                ? 'Offline: menampilkan katalog produk tersimpan terakhir'
                : null,
            error: cached.isEmpty ? _message(e) : null,
          ));
        }
      } else if (!isClosed) {
        emit(state.copyWith(loading: false, loadingMore: false, error: _message(e)));
      }
    }
  }

  String _message(Object e) =>
      e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e');

  void loadMore() {
    if (state.loading || state.loadingMore || state.lastPage) return;
    loadProduk(append: true);
  }

  void setCategory(Object id) {
    if (id == state.activeKat) return;
    loadProduk(categoryId: id);
  }

  void setShiftActive(bool active) => emit(state.copyWith(shiftActive: active));

  // Nyicil ambil & simpan info varian tiap produk yang baru dimuat, di
  // background — supaya SEMUA produk (bukan cuma yang pernah ditap) bisa
  // langsung dimasukkan ke keranjang saat offline nanti, tanpa nunggu
  // panggilan API per-produk lebih dulu. Sengaja berurutan (bukan paralel)
  // biar tidak membanjiri server; berhenti diam-diam kalau gagal.
  Future<void> _prefetchModifiers(List<Produk> produk) async {
    for (final p in produk) {
      if (isClosed || _modCache.containsKey(p.id)) continue;
      try {
        final groups = await _repo.modifierFor(p.id);
        if (isClosed) return;
        _modCache[p.id] = groups;
        cacheModifier(p.id, groups);
      } catch (_) {
        return; // biasanya berarti offline — hentikan, coba lagi lain kali
      }
    }
  }

  Future<List<ModifierGroup>> modifierFor(Produk p) async {
    final cached = _modCache[p.id];
    if (cached != null) return cached;
    try {
      final groups = await _repo.modifierFor(p.id);
      _modCache[p.id] = groups;
      cacheModifier(p.id, groups);
      return groups;
    } catch (e) {
      if (isNetworkError(e)) {
        final offline = await readCachedModifier(p.id);
        if (offline != null) {
          _modCache[p.id] = offline;
          return offline;
        }
      }
      rethrow;
    }
  }
}
