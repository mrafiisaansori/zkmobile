import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'admin_shell.dart';
import 'api.dart';
import 'login_page.dart';
import 'shell.dart';
import 'theme.dart';

// Ditampilkan sebelum sesi tersedia (Session.restore) — durasi minimum dijaga
// agar animasi logo sempat terlihat, baru pindah ke Login/Shell.
class BootPage extends StatefulWidget {
  const BootPage({super.key});
  @override
  State<BootPage> createState() => _BootPageState();
}

class _BootPageState extends State<BootPage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      Session.restore(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashScreen();
    return shellForRole(Session.token != null ? Session.user?.role : null);
  }
}

// Satu tempat buat mapping role -> shell (dipakai BootPage & login).
Widget shellForRole(String? role) => switch (role) {
      'kasir' => const KasirShell(),
      'admin' => const AdminShell(),
      _ => const LoginPage(),
    };

// Transisi singkat: tampilkan animasi splash sebentar sebelum masuk ke halaman
// berikutnya — dipakai setelah login berhasil.
class SplashGate extends StatefulWidget {
  final Widget next;
  final Duration duration;
  const SplashGate(
      {super.key, required this.next, this.duration = const Duration(milliseconds: 1400)});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => _ready ? widget.next : const SplashScreen();
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat();
  // Putar 0->180°, jeda sebentar, lanjut putar 180->360°, jeda lagi, ulang.
  late final _angle = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 0.0, end: math.pi).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 38),
    TweenSequenceItem(tween: ConstantTween(math.pi), weight: 14),
    TweenSequenceItem(
        tween: Tween(begin: math.pi, end: 2 * math.pi)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 38),
    TweenSequenceItem(tween: ConstantTween(2 * math.pi), weight: 10),
  ]).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ZK.ink,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ZK.ink, Color(0xFF073B73), ZK.primary],
                ),
              ),
            ),
            Opacity(
              opacity: 0.14,
              child: Image.asset('assets/login_illustration.jpeg',
                  fit: BoxFit.cover, alignment: Alignment.topCenter),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _angle,
                    builder: (_, child) =>
                        Transform.rotate(angle: _angle.value, child: child),
                    child:
                        Image.asset('assets/logo_splash.png', height: 76, width: 76),
                  ),
                  const SizedBox(height: 18),
                  const Text('ZONA KASIR',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text('zonakasir.com',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
}
