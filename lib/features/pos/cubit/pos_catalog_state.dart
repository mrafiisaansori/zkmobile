import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';

// Padanan state lepas-setState PosPageState lama untuk grid produk +
// referensi (kategori/metode bayar/pajak/qris) + status sesi kasir.
class PosCatalogState extends Equatable {
  final List<Produk> produk;
  final List<Kategori> kategori;
  final List<JenisBayar> jenisBayar;
  final TaxSetting? tax;
  final Qris? qris;
  // 'all' atau id kategori (int) — dibiarkan Object seperti kode lama supaya
  // chip "Semua" & chip per-kategori bisa dibandingkan langsung.
  final Object activeKat;
  final String search;
  final bool loading, loadingMore, lastPage;
  final int page;
  final bool shiftActive;
  // Pesan toast satu-kali buat PosPage (BlocListener) — TIDAK fallback ke
  // nilai lama di copyWith (lihat pola sama di DashboardState), jadi tiap
  // emit baru otomatis "bersih" dan listener tidak menampilkan toast dua kali.
  final String? error;
  final String? info;

  const PosCatalogState({
    this.produk = const [],
    this.kategori = const [],
    this.jenisBayar = const [],
    this.tax,
    this.qris,
    this.activeKat = 'all',
    this.search = '',
    this.loading = true,
    this.loadingMore = false,
    this.lastPage = false,
    this.page = 1,
    this.shiftActive = true,
    this.error,
    this.info,
  });

  PosCatalogState copyWith({
    List<Produk>? produk,
    List<Kategori>? kategori,
    List<JenisBayar>? jenisBayar,
    TaxSetting? tax,
    bool clearTax = false,
    Qris? qris,
    bool clearQris = false,
    Object? activeKat,
    String? search,
    bool? loading,
    bool? loadingMore,
    bool? lastPage,
    int? page,
    bool? shiftActive,
    String? error,
    String? info,
  }) =>
      PosCatalogState(
        produk: produk ?? this.produk,
        kategori: kategori ?? this.kategori,
        jenisBayar: jenisBayar ?? this.jenisBayar,
        tax: clearTax ? null : (tax ?? this.tax),
        qris: clearQris ? null : (qris ?? this.qris),
        activeKat: activeKat ?? this.activeKat,
        search: search ?? this.search,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        lastPage: lastPage ?? this.lastPage,
        page: page ?? this.page,
        shiftActive: shiftActive ?? this.shiftActive,
        error: error, // tidak fallback ke this.error — tiap emit baru "bersih".
        info: info,
      );

  @override
  List<Object?> get props => [
        produk,
        kategori,
        jenisBayar,
        tax,
        qris,
        activeKat,
        search,
        loading,
        loadingMore,
        lastPage,
        page,
        shiftActive,
        error,
        info,
      ];
}
