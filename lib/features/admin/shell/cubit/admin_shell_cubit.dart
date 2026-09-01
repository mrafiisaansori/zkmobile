import 'package:flutter_bloc/flutter_bloc.dart';

// Padanan `_index`/`select()` di AdminShellState lama — cuma menyimpan menu
// admin yang aktif. Static `current` mereplikasi pola `AdminShellState.current`
// lama: halaman admin yang di-push DI ATAS shell (mis. form produk) bukan
// descendant widget tree BlocProvider-nya, jadi tetap butuh reach-through
// statis untuk memindah tab shell dari luar.
class AdminShellCubit extends Cubit<int> {
  AdminShellCubit() : super(0) {
    current = this;
  }

  static AdminShellCubit? current;

  void select(int i) => emit(i);

  @override
  Future<void> close() {
    if (identical(current, this)) current = null;
    return super.close();
  }
}
