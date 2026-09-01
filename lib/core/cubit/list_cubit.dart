import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/api_client.dart';

enum ListStatus { initial, loading, loadingMore, ready, error }

// State generik untuk halaman list+search+paginate — dipakai oleh POS
// catalog dan tiap halaman admin CRUD (produk, kategori, satuan, supplier,
// member, pengguna, voucher, stok, pembelian, retur, transaksi, dst).
class ListState<T> extends Equatable {
  final ListStatus status;
  final List<T> items;
  final String search;
  final int page;
  final bool hasMore;
  final String? error;

  const ListState({
    this.status = ListStatus.initial,
    this.items = const [],
    this.search = '',
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  ListState<T> copyWith({
    ListStatus? status,
    List<T>? items,
    String? search,
    int? page,
    bool? hasMore,
    String? error,
  }) =>
      ListState<T>(
        status: status ?? this.status,
        items: items ?? this.items,
        search: search ?? this.search,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );

  @override
  List<Object?> get props => [status, items, search, page, hasMore, error];
}

// fetchPage(search, page) mengembalikan satu halaman data — kontrak yang sama
// dipakai semua Api.xxx(search:, page:) di core/network + tiap repository
// fitur. deleteItem opsional (halaman read-only seperti Riwayat tidak perlu).
//
// ponytail: satu Cubit generik dipakai ulang di ~10 halaman admin identik,
// daripada bikin ProdukCubit/KategoriCubit/SatuanCubit/... satu-satu.
class ListCubit<T> extends Cubit<ListState<T>> {
  final Future<List<T>> Function({String? search, int page}) fetchPage;
  final Future<void> Function(T item)? deleteItem;
  final int pageSize;

  ListCubit({required this.fetchPage, this.deleteItem, this.pageSize = 25})
      : super(const ListState());

  Future<void> load({String? search}) async {
    emit(state.copyWith(
        status: ListStatus.loading, search: search ?? state.search, page: 1));
    try {
      final items = await fetchPage(search: state.search, page: 1);
      emit(state.copyWith(
          status: ListStatus.ready,
          items: items,
          page: 1,
          hasMore: items.length >= pageSize));
    } catch (e) {
      emit(state.copyWith(status: ListStatus.error, error: _message(e)));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == ListStatus.loadingMore) return;
    emit(state.copyWith(status: ListStatus.loadingMore));
    try {
      final next = state.page + 1;
      final items = await fetchPage(search: state.search, page: next);
      emit(state.copyWith(
          status: ListStatus.ready,
          items: [...state.items, ...items],
          page: next,
          hasMore: items.length >= pageSize));
    } catch (e) {
      emit(state.copyWith(status: ListStatus.error, error: _message(e)));
    }
  }

  Future<void> refresh() => load(search: state.search);

  Future<bool> remove(T item) async {
    if (deleteItem == null) return false;
    try {
      await deleteItem!(item);
      emit(state.copyWith(items: state.items.where((e) => e != item).toList()));
      return true;
    } catch (e) {
      emit(state.copyWith(error: _message(e)));
      return false;
    }
  }

  String _message(Object e) =>
      e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e');
}
