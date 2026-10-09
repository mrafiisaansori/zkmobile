import 'package:flutter_bloc/flutter_bloc.dart';

// Judul+subjudul per tab shell, buat header tablet (HeroShell butuh tahu
// halaman aktif tanpa tiap page harus mengoper title-nya sendiri).
// Di-emit oleh ShellCubit.goTo(), dibaca oleh HeroShell lewat BlocBuilder.
// Global/lintas-fitur (seperti ThemeCubit) makanya di core/, bukan di
// features/shell/ — shared/widgets/hero_shell.dart tidak boleh bergantung
// balik ke sebuah feature.
class ActiveTabCubit extends Cubit<int> {
  ActiveTabCubit() : super(0);
  void set(int tab) => emit(tab);
}

const tabTitles = [
  ('Dashboard', 'Ringkasan performa bisnis Anda'),
  ('Kasir', 'Kelola transaksi penjualan'),
  ('Open Bill', 'Kelola tagihan tertunda'),
  ('Sesi Kas', 'Kelola sesi kasir'),
  ('Riwayat', 'Riwayat transaksi penjualan'),
];
