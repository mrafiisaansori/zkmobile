import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/navigation/active_tab_cubit.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/screens/login_page.dart';
import 'features/boot/screens/splash_page.dart';
import 'features/pos/cubit/cart_cubit.dart';
import 'shared/widgets/widgets.dart';

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
          navigatorKey: _navKey,
          builder: (_, child) => _IdleLogout(child: child!),
          home: const BootPage(),
        ),
      ),
    );
  }
}

final _navKey = GlobalKey<NavigatorState>();

// Catat tiap sentuhan sebagai aktivitas, dan logout otomatis begitu
// Session.idleTimeout terlewati — dicek tiap menit dan saat app kembali dibuka.
class _IdleLogout extends StatefulWidget {
  final Widget child;
  const _IdleLogout({required this.child});
  @override
  State<_IdleLogout> createState() => _IdleLogoutState();
}

class _IdleLogoutState extends State<_IdleLogout> with WidgetsBindingObserver {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check());
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!Session.idleExpired) return;
    await Session.clear();
    final nav = _navKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    // Context navigator ada di atas Overlay-nya, jadi toast pakai context overlay.
    final ctx = nav.overlay?.context;
    if (ctx != null && ctx.mounted) {
      toastError(ctx,'Sesi berakhir karena tidak ada aktivitas selama 3 jam. Silakan login lagi.');
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => Session.touch(),
        child: widget.child,
      );
}
