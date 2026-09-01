import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/shell_repository.dart';

// Padanan KasirShellState lama (_tab + _shiftActive), minus urusan animasi
// (tetap di widget, butuh TickerProvider) dan minus GlobalKey reach-through.
class ShellState extends Equatable {
  final int tab;
  final bool shiftActive;
  const ShellState({this.tab = 0, this.shiftActive = true});

  ShellState copyWith({int? tab, bool? shiftActive}) => ShellState(
        tab: tab ?? this.tab,
        shiftActive: shiftActive ?? this.shiftActive,
      );

  @override
  List<Object?> get props => [tab, shiftActive];
}

// Design decision (lihat laporan batch): GlobalKey reach-through
// (_posKey.currentState?.refreshAfterBill(), _openBillKey.currentState?.refresh())
// diganti dua cara berbeda tergantung sifatnya:
//  - openPos(): cuma pindah tab. PosPage sudah reaktif ke CartCubit (yang sudah
//    di-loadBill() SEBELUM openPos() dipanggil), jadi tidak perlu sinyal apa pun
//    lagi — dia baca ulang isi keranjang sendiri lewat BlocBuilder/watch.
//  - goToOpenBill(): juga cuma pindah tab (index 2). OpenBillPage sendiri yang
//    dengar ShellCubit lewat BlocListener (listenWhen: tab berubah jadi 2) dan
//    panggil OpenBillCubit.refresh() saat itu — sesuai instruksi "screens react
//    to being shown" alih-alih shell yang menjangkau state widget anak.
//
// ShellCubit sendiri disediakan LOKAL oleh KasirShell (bukan di root
// MultiBlocProvider — itu belum ada, urusan batch wiring nanti). Supaya
// halaman yang di-push DI ATAS shell (RiwayatDetailPage, lewat Navigator biasa
// jadi bukan descendant widget tree KasirShell) tetap bisa baca status sesi &
// pindah tab, dipakai singleton statis `ShellCubit.instance` — padanan persis
// `KasirShellState.current` lama (dan gaya `Cart.i` / `AdminShellState.current`
// yang sudah ada di app ini).
class ShellCubit extends Cubit<ShellState> {
  final ShellRepository _repo;
  static ShellCubit? instance;

  ShellCubit({ShellRepository? repository, int initialTab = 0})
      : _repo = repository ?? ShellRepository(),
        super(ShellState(tab: initialTab)) {
    instance = this;
    _refreshShift();
  }

  Future<void> _refreshShift() async {
    final aktif = await _repo.shiftActive();
    if (!isClosed) emit(state.copyWith(shiftActive: aktif));
  }

  void goTo(int tab) {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab));
    _refreshShift();
  }

  // Buka POS dengan bill yang sudah dimuat ke CartCubit oleh pemanggil.
  void openPos() => goTo(1);

  // Pindah ke tab Open Bill — OpenBillPage me-refresh dirinya sendiri saat
  // mendeteksi tab berubah jadi miliknya (lihat komentar kelas di atas).
  void goToOpenBill() => goTo(2);

  @override
  Future<void> close() {
    if (identical(instance, this)) instance = null;
    return super.close();
  }
}
