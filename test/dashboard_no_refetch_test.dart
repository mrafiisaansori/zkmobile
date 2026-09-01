import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Reproduksi persis pola di KasirShell (lib/features/shell/screens/kasir_shell.dart):
// `pages` adalah const list di dalam method yang dipanggil ulang tiap build,
// ditampilkan lewat IndexedStack, salah satu halamannya bikin Cubit lewat
// BlocProvider(create: ...) yang langsung .load() saat dibuat.
//
// Pertanyaannya: apakah pindah tab (yang men-trigger setState + rebuild
// parent) bikin BlocProvider itu membuat Cubit baru lagi (= fetch ulang)?
int _createCount = 0;

class _FakeCubit extends Cubit<int> {
  _FakeCubit() : super(0) {
    _createCount++; // padanan `..load()` — hitung tiap kali Cubit baru dibuat
  }
}

class _DashboardLike extends StatelessWidget {
  const _DashboardLike();
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => _FakeCubit(),
        // BlocProvider itu lazy — Cubit baru benar-benar dibuat begitu ADA
        // yang membacanya. DashboardPage asli baca lewat BlocConsumer di
        // _DashboardView, jadi consumer di sini wajib ada juga supaya test
        // ini representatif (bukan cuma nembak angka).
        child: Builder(
          builder: (context) {
            context.watch<_FakeCubit>();
            return const Text('dashboard', textDirection: TextDirection.ltr);
          },
        ),
      );
}

class _ShellLike extends StatefulWidget {
  const _ShellLike();
  @override
  State<_ShellLike> createState() => _ShellLikeState();
}

class _ShellLikeState extends State<_ShellLike> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Sama persis seperti _buildScaffold di kasir_shell.dart: const list
    // dievaluasi ulang tiap build, tapi tetap widget instance yang sama
    // (const-canonicalized) karena literal const di lokasi kode yang sama.
    final pages = const [
      _DashboardLike(),
      Text('pos', textDirection: TextDirection.ltr),
      Text('open_bill', textDirection: TextDirection.ltr),
    ];
    return Column(
      children: [
        IndexedStack(index: _tab, children: pages),
        ElevatedButton(
          key: const Key('switch'),
          onPressed: () => setState(() => _tab = (_tab + 1) % 3),
          child: const Text('switch tab'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets(
      'switching IndexedStack tabs (const children, parent setState) does NOT recreate a BlocProvider.create Cubit already mounted',
      (tester) async {
    _createCount = 0;
    await tester.pumpWidget(const MaterialApp(home: _ShellLike()));

    expect(_createCount, 1, reason: 'Cubit dibuat sekali saat halaman pertama kali mount');

    // Pindah tab beberapa kali (Dashboard -> POS -> Open Bill -> Dashboard -> ...).
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('switch')));
      await tester.pump();
    }

    expect(_createCount, 1,
        reason:
            'Pindah tab lewat IndexedStack TIDAK boleh bikin DashboardCubit baru / fetch ulang selama widget const-nya identik di setiap rebuild');
  });
}
