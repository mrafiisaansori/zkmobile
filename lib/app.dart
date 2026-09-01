import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/navigation/active_tab_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/boot/screens/splash_page.dart';
import 'features/pos/cubit/cart_cubit.dart';

// Root widget — padanan lib/main.dart lama (ZkApp), ditambah satu
// MultiBlocProvider yang menggantikan seluruh ValueNotifier global lama
// (themeMode, isOffline, activeTab) plus CartCubit sebagai pengganti
// singleton `Cart.i`: satu instance dibuat di sini, dibagi ke seluruh app
// lewat context.read/watch<CartCubit>() — persis cakupan singleton lama,
// cuma lewat provider bukan static field.
class ZkApp extends StatelessWidget {
  const ZkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()..load()),
        BlocProvider(create: (_) => ConnectivityCubit()..start()),
        BlocProvider(create: (_) => ActiveTabCubit()),
        BlocProvider(create: (_) => CartCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (_, mode) => MaterialApp(
          title: 'Zona Kasir',
          debugShowCheckedModeBanner: false,
          theme: zkTheme,
          darkTheme: zkDarkTheme,
          themeMode: mode,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('id'), Locale('en')],
          locale: const Locale('id'),
          home: const BootPage(),
        ),
      ),
    );
  }
}
