import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/navigation/active_tab_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../closing/screens/closing_page.dart';
import '../../dashboard/screens/dashboard_page.dart';
import '../../open_bill/screens/open_bill_page.dart';
import '../../pos/cubit/cart_cubit.dart';
import '../../pos/cubit/cart_state.dart';
import '../../pos/screens/pos_page.dart';
import '../../riwayat/screens/riwayat_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/shell_cubit.dart';
import '../widgets/tablet_sidebar.dart';

// Padanan menu kasir di constants/nav.ts: Dashboard, POS, Open Bill,
// Buka/Tutup Kasir, Riwayat. Lihat shell_cubit.dart untuk keputusan desain
// pengganti GlobalKey reach-through lama.
class KasirShell extends StatefulWidget {
  final int initialTab;
  const KasirShell({super.key, this.initialTab = 0});
  @override
  State<KasirShell> createState() => _KasirShellState();
}

class _KasirShellState extends State<KasirShell> with SingleTickerProviderStateMixin {
  late final ShellCubit _cubit = ShellCubit(initialTab: widget.initialTab);
  late int _displayTab = widget.initialTab;
  int _switchToken = 0;

  // Fade-through ala Material: konten lama pudar dulu (reverse), baru
  // konten baru muncul dengan fade+scale (forward) — bukan potong instan.
  // Tetap tinggal di widget (butuh TickerProvider), dipicu oleh perubahan
  // tab di ShellCubit lewat BlocListener alih-alih dipanggil langsung dari
  // sini seperti goTo() lama.
  late final _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150))
    ..value = 1;
  late final _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOutCubic);
  late final _scale = Tween(begin: 0.97, end: 1.0)
      .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    context.read<ActiveTabCubit>().set(_displayTab);
  }

  Future<void> _playTransition(int newTab) async {
    final token = ++_switchToken;
    await _fadeCtrl.reverse();
    if (!mounted || token != _switchToken) return;
    setState(() => _displayTab = newTab);
    context.read<ActiveTabCubit>().set(newTab);
    await _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ShellCubit, ShellState>(
        listenWhen: (prev, curr) => prev.tab != curr.tab,
        listener: (context, state) => _playTransition(state.tab),
        child: _buildScaffold(context, dark),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, bool dark) {
    final pages = const [
      DashboardPage(),
      PosPage(),
      OpenBillPage(),
      ClosingPage(),
      RiwayatPage(),
    ];
    final content = FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: IndexedStack(index: _displayTab, children: pages),
      ),
    );
    if (isTablet(context)) {
      return Scaffold(
        backgroundColor: dark ? ZK.bgDark : ZK.background,
        body: BlocBuilder<ShellCubit, ShellState>(
          builder: (context, shellState) => BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) => Row(
              children: [
                TabletSidebar(
                  selectedIndex: _displayTab,
                  onSelect: (i) => _cubit.goTo(i),
                  shiftActive: shellState.shiftActive,
                  cartCount: cartState.count,
                ),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: dark ? ZK.bgDark : ZK.background,
      body: content,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.4 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? ZK.primary
                    : (dark ? Colors.white60 : ZK.slate600))),
          ),
          child: NavigationBar(
            selectedIndex: _displayTab,
            onDestinationSelected: (i) => _cubit.goTo(i),
            height: 66,
            elevation: 0,
            backgroundColor: dark ? ZK.cardDark : Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: dark ? ZK.primary.withValues(alpha: 0.22) : ZK.brand50,
            indicatorShape: const StadiumBorder(),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                  icon: MenuIcon(name: 'dashboard', active: false),
                  selectedIcon: MenuIcon(name: 'dashboard', active: true),
                  label: 'Dashboard'),
              NavigationDestination(
                icon: _cartBadge(const MenuIcon(name: 'kasir', active: false)),
                selectedIcon: _cartBadge(const MenuIcon(name: 'kasir', active: true)),
                label: 'Kasir',
              ),
              const NavigationDestination(
                  icon: MenuIcon(name: 'openbill', active: false),
                  selectedIcon: MenuIcon(name: 'openbill', active: true),
                  label: 'Open Bill'),
              const NavigationDestination(
                  icon: MenuIcon(name: 'kas', active: false),
                  selectedIcon: MenuIcon(name: 'kas', active: true),
                  label: 'Sesi Kas'),
              const NavigationDestination(
                  icon: MenuIcon(name: 'riwayat', active: false),
                  selectedIcon: MenuIcon(name: 'riwayat', active: true),
                  label: 'Riwayat'),
            ],
          ),
        ),
      ),
    );
  }

  // Badge jumlah keranjang — dipakai ikon Kasir terpilih maupun tidak.
  Widget _cartBadge(Widget child) => BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) => Badge(
          isLabelVisible: cartState.count > 0,
          label: Text('${cartState.count}'),
          child: child,
        ),
      );
}
