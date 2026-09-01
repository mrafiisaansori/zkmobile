import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Preferensi tema global — dipakai lewat toggle di header & login.
// Ganti dari ValueNotifier<ThemeMode> ke Cubit: state sama persis, cuma
// dikonsumsi lewat BlocBuilder/context.watch alih-alih ValueListenableBuilder.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    emit(sp.getString('theme_mode') == 'dark' ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggle() async {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('theme_mode', state == ThemeMode.dark ? 'dark' : 'light');
  }
}
