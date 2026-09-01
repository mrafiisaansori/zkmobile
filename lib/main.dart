import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'connectivity.dart';
import 'splash_page.dart';
import 'theme.dart';
import 'toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemeMode();
  initConnectivityWatcher();
  // Tablet dibuka landscape secara default — layout POS/sidebar didesain
  // buat lebar. Ponsel dibiarkan bebas seperti biasa.
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  if (size.shortestSide >= 600) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }
  runApp(const ZkApp());
}

class ZkApp extends StatelessWidget {
  const ZkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, mode, __) => MaterialApp(
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
    );
  }
}

String rupiah(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp ${v < 0 ? '-' : ''}$b';
}

// Error jaringan mentah (SocketException dsb) tampil jelek & teknis —
// diseragamkan jadi satu pesan yang manusiawi, dari satu tempat ini saja
// biar konsisten di semua halaman (dashboard, riwayat, POS, dst).
void toastError(BuildContext ctx, Object e) => showAppToast(
    ctx,
    e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e'),
    ToastKind.error);
void toastOk(BuildContext ctx, String text) =>
    showAppToast(ctx, text, ToastKind.success);
