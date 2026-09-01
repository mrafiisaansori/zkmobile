import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'closing_page.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'open_bill_page.dart';
import 'pos_page.dart';
import 'riwayat_page.dart';
import 'theme.dart';

// Padanan menu kasir di constants/nav.ts: Dashboard, POS, Open Bill,
// Buka/Tutup Kasir, Riwayat.
class KasirShell extends StatefulWidget {
  final int initialTab;
  const KasirShell({super.key, this.initialTab = 0});
  @override
  State<KasirShell> createState() => KasirShellState();

  // Pindah tab dari mana saja (mis. Open Bill -> POS setelah bill dimuat).
  static KasirShellState of(BuildContext c) =>
      c.findAncestorStateOfType<KasirShellState>()!;
}

// Referensi singleton ke shell yang sedang hidup (padanan Cart.i) — dipakai
// halaman yang di-push di ATAS shell (mis. detail riwayat) supaya sidebar
// tablet-nya bisa pindah tab shell walau bukan descendant widget tree shell.

class KasirShellState extends State<KasirShell> with SingleTickerProviderStateMixin {
  late int _tab = widget.initialTab;
  final _posKey = GlobalKey<PosPageState>();
  final _openBillKey = GlobalKey<OpenBillPageState>();
  // Fade-through ala Material: konten lama pudar dulu (reverse), baru
  // konten baru muncul dengan fade+scale (forward) — bukan potong instan.
  late final _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150))
    ..value = 1;
  late final _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOutCubic);
  late final _scale = Tween(begin: 0.97, end: 1.0)
      .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
  int _switchToken = 0;
  bool _shiftActive = false;

  static KasirShellState? current;
  bool get shiftActiveValue => _shiftActive;

  @override
  void initState() {
    super.initState();
    current = this;
    activeTab.value = _tab;
    _refreshShift();
  }

  Future<void> _refreshShift() async {
    try {
      final aktif = await Api.shiftActive();
      if (mounted) setState(() => _shiftActive = aktif);
    } catch (_) {}
  }

  Future<void> goTo(int i) async {
    if (i == _tab) return;
    final token = ++_switchToken;
    await _fadeCtrl.reverse();
    if (!mounted || token != _switchToken) return;
    setState(() => _tab = i);
    activeTab.value = i;
    _refreshShift();
    await _fadeCtrl.forward();
  }

  @override
  void dispose() {
    if (identical(current, this)) current = null;
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Buka POS dengan bill yang sudah dimuat ke keranjang.
  void openPos() {
    goTo(1);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _posKey.currentState?.refreshAfterBill());
  }

  // Pindah ke tab Open Bill lalu muat ulang datanya (IndexedStack menjaga
  // halaman tetap hidup, jadi initState tidak jalan ulang sendiri).
  void goToOpenBill() {
    goTo(2);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _openBillKey.currentState?.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      const DashboardPage(),
      PosPage(key: _posKey),
      OpenBillPage(key: _openBillKey),
      const ClosingPage(),
      const RiwayatPage(),
    ];
    final content = FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: IndexedStack(index: _tab, children: pages),
      ),
    );
    if (isTablet(context)) {
      return Scaffold(
        backgroundColor: dark ? ZK.bgDark : ZK.background,
        body: AnimatedBuilder(
          animation: Cart.i,
          builder: (_, __) => Row(
            children: [
              TabletSidebar(selectedIndex: _tab, onSelect: goTo, shiftActive: _shiftActive),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: dark ? ZK.bgDark : ZK.background,
      body: content,
      bottomNavigationBar: AnimatedBuilder(
        animation: Cart.i,
        builder: (_, __) => DecoratedBox(
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
              selectedIndex: _tab,
              onDestinationSelected: goTo,
              height: 66,
              elevation: 0,
              backgroundColor: dark ? ZK.cardDark : Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: dark ? ZK.primary.withValues(alpha: 0.22) : ZK.brand50,
              indicatorShape: const StadiumBorder(),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined,
                        color: dark ? Colors.white60 : ZK.slate600),
                    selectedIcon: const Icon(Icons.dashboard, color: ZK.primary),
                    label: 'Dashboard'),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: Cart.i.count > 0,
                    label: Text('${Cart.i.count}'),
                    child: Icon(Icons.point_of_sale_outlined,
                        color: dark ? Colors.white60 : ZK.slate600),
                  ),
                  selectedIcon: const Icon(Icons.point_of_sale, color: ZK.primary),
                  label: 'Kasir',
                ),
                NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined,
                        color: dark ? Colors.white60 : ZK.slate600),
                    selectedIcon: const Icon(Icons.receipt_long, color: ZK.primary),
                    label: 'Open Bill'),
                NavigationDestination(
                    icon: Icon(Icons.lock_open_outlined,
                        color: dark ? Colors.white60 : ZK.slate600),
                    selectedIcon: const Icon(Icons.lock_open, color: ZK.primary),
                    label: 'Buka/Tutup Kas'),
                NavigationDestination(
                    icon: Icon(Icons.history_outlined,
                        color: dark ? Colors.white60 : ZK.slate600),
                    selectedIcon: const Icon(Icons.history, color: ZK.primary),
                    label: 'Riwayat'),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// Sidebar tablet reusable — dipakai KasirShell sendiri, dan juga halaman
// yang di-push di atasnya (mis. detail riwayat) lewat KasirShellState.current
// supaya semua halaman tablet punya chrome yang sama persis.
class TabletSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool shiftActive;
  const TabletSidebar(
      {super.key, required this.selectedIndex, required this.onSelect, required this.shiftActive});

  Future<void> _logout(BuildContext context) async {
    await Session.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        border: Border(right: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
      ),
      child: Column(
        children: [
          _header(dark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _item(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', dark),
                _item(1, Icons.point_of_sale_outlined, Icons.point_of_sale, 'Kasir', dark,
                    badge: Cart.i.count > 0 ? '${Cart.i.count}' : null),
                _item(2, Icons.receipt_long_outlined, Icons.receipt_long, 'Open Bill', dark),
                _item(3, Icons.lock_open_outlined, Icons.lock_open, 'Buka/Tutup Kas', dark),
                _item(4, Icons.history_outlined, Icons.history, 'Riwayat', dark),
              ],
            ),
          ),
          _footer(context, dark),
        ],
      ),
    );
  }

  // Header sidebar tablet: logo + wordmark — sidebar tablet selalu terbuka,
  // tidak ada tombol show/hide lagi.
  Widget _header(bool dark) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
        child: Row(
          children: [
            Image.asset('assets/logo.png', height: 36, width: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ZONA KASIR',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : ZK.ink)),
                  Text('Solusi Bisnis Anda',
                      style:
                          TextStyle(fontSize: 10, color: dark ? Colors.white54 : ZK.slate500)),
                ],
              ),
            ),
          ],
        ),
      );

  // Satu item navigasi sidebar — terpilih = pil biru penuh lebar (padanan
  // desain mockup), bukan sekadar indikator kecil di sekitar ikon.
  Widget _item(int index, IconData icon, IconData selectedIcon, String label, bool dark,
      {String? badge}) {
    final selected = selectedIndex == index;
    final iconWidget = Icon(selected ? selectedIcon : icon,
        size: 20, color: selected ? Colors.white : (dark ? Colors.white60 : ZK.slate600));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r12,
          onTap: () => onSelect(index),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: selected ? ZK.primary : null, borderRadius: r12),
            child: Row(
              children: [
                badge == null
                    ? iconWidget
                    : Badge(label: Text(badge), child: iconWidget),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (dark ? Colors.white70 : ZK.slate600))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Blok profil kasir di bawah sidebar tablet (nama, status sesi, toggle
  // tema, logout).
  Widget _footer(BuildContext context, bool dark) {
    final nama = Session.user?.nama ?? '';
    final initials = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: dark ? ZK.lineDark : ZK.line),
          const SizedBox(height: 4),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ZK.brand100,
                child: Text(initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: ZK.brand700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nama.isEmpty ? '-' : nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : ZK.ink)),
                    Row(
                      children: [
                        Container(
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: shiftActive ? ZK.primary : ZK.slate400),
                        ),
                        const SizedBox(width: 4),
                        Text(shiftActive ? 'Sesi aktif' : 'Sesi tidak aktif',
                            style: TextStyle(
                                fontSize: 10.5, color: dark ? Colors.white54 : ZK.slate500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: toggleThemeMode,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: dark ? Colors.white70 : ZK.slate600,
                      side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 17),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: dark ? Colors.white70 : ZK.slate600,
                      side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: const Icon(Icons.logout, size: 17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
