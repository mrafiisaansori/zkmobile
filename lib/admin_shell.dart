import 'package:flutter/material.dart';
import 'admin_closing_page.dart';
import 'admin_katalog_page.dart';
import 'admin_keuangan_page.dart';
import 'admin_kategori_page.dart';
import 'admin_langganan_page.dart';
import 'admin_member_page.dart';
import 'admin_pembelian_page.dart';
import 'admin_pengaturan_page.dart';
import 'admin_pengguna_page.dart';
import 'admin_produk_page.dart';
import 'admin_retur_page.dart';
import 'admin_satuan_page.dart';
import 'admin_stok_page.dart';
import 'admin_supplier_page.dart';
import 'admin_transaksi_page.dart';
import 'admin_varian_page.dart';
import 'admin_voucher_page.dart';
import 'api.dart';
import 'login_page.dart';
import 'main.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

// Shell untuk role admin (back-office, tanpa akses jual/POS) — padanan
// src/constants/nav.ts bagian admin di web. Fase 1: shell + navigasi lengkap
// sudah jadi, tapi baru Dashboard yang fungsional; menu lain "Segera hadir".
class _NavItem {
  final String title;
  final IconData icon;
  const _NavItem(this.title, this.icon);
}

class _NavGroup {
  final String? label;
  final List<_NavItem> items;
  const _NavGroup(this.label, this.items);
}

const _groups = [
  _NavGroup(null, [_NavItem('Dashboard', Icons.dashboard_outlined)]),
  _NavGroup('Master Data', [
    _NavItem('Kategori', Icons.sell_outlined),
    _NavItem('Satuan', Icons.straighten_outlined),
    _NavItem('Varian', Icons.layers_outlined),
    _NavItem('Produk', Icons.inventory_2_outlined),
    _NavItem('Supplier', Icons.local_shipping_outlined),
    _NavItem('Member', Icons.people_outline),
    _NavItem('Pengguna', Icons.manage_accounts_outlined),
    _NavItem('Voucher', Icons.confirmation_number_outlined),
  ]),
  _NavGroup('Operasional', [
    _NavItem('Stok Opname', Icons.inventory_outlined),
    _NavItem('Pembelian Barang', Icons.shopping_cart_outlined),
    _NavItem('Retur Barang', Icons.assignment_return_outlined),
    _NavItem('Katalog', Icons.storefront_outlined),
  ]),
  _NavGroup('Laporan', [
    _NavItem('Laporan Transaksi', Icons.receipt_long_outlined),
    _NavItem('Laporan Keuangan', Icons.bar_chart_outlined),
    _NavItem('Laporan Closing', Icons.fact_check_outlined),
  ]),
  _NavGroup('Lainnya', [
    _NavItem('Pengaturan', Icons.settings_outlined),
    _NavItem('Langganan', Icons.workspace_premium_outlined),
  ]),
];

final List<_NavItem> _flat = [for (final g in _groups) ...g.items];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => AdminShellState();
}

// Referensi singleton (padanan KasirShellState.current) — dipakai halaman
// admin yang di-push DI ATAS shell (mis. form produk) supaya sidebar
// tablet-nya bisa pindah tab shell walau bukan descendant widget tree-nya.
class AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  static AdminShellState? current;

  @override
  void initState() {
    super.initState();
    current = this;
  }

  @override
  void dispose() {
    if (identical(current, this)) current = null;
    super.dispose();
  }

  void select(int i) {
    setState(() => _index = i);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _logout() async {
    await Session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final item = _flat[_index];
    final content = switch (_index) {
      0 => const AdminDashboardPage(),
      1 => const AdminKategoriPage(),
      2 => const AdminSatuanPage(),
      3 => const AdminVarianPage(),
      4 => const AdminProdukPage(),
      5 => const AdminSupplierPage(),
      6 => const AdminMemberPage(),
      7 => const AdminPenggunaPage(),
      8 => const AdminVoucherPage(),
      9 => const AdminStokPage(),
      10 => const AdminPembelianPage(),
      11 => const AdminReturPage(),
      12 => const AdminKatalogPage(),
      13 => const AdminTransaksiPage(),
      14 => const AdminKeuanganPage(),
      15 => const AdminClosingPage(),
      16 => const AdminPengaturanPage(),
      17 => const AdminLanggananPage(),
      _ => _ComingSoonPage(item: item),
    };
    final hero = HeroShell(
      titleOverride: item.title,
      subtitleOverride: 'Menu admin',
      onMenuTap: isTablet(context) ? null : () => _scaffoldKey.currentState?.openDrawer(),
      child: content,
    );

    if (isTablet(context)) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: dark ? ZK.bgDark : ZK.background,
        body: Row(
          children: [
            AdminSidebar(selected: _index, onSelect: select, onLogout: _logout),
            Expanded(child: hero),
          ],
        ),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: dark ? ZK.bgDark : ZK.background,
      drawer: Drawer(
        width: 280,
        // Drawer nempel ke status bar tanpa header sendiri (beda dari
        // sidebar tablet yang punya logo di atas) — kasih SafeArea + jarak
        // supaya item pertama tidak mepet ke atas layar.
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _AdminMenuList(selected: _index, onSelect: select, onLogout: _logout),
          ),
        ),
      ),
      body: hero,
    );
  }
}

// Sidebar tablet — daftar menu dikelompokkan biar 18 item tetap gampang
// dipindai, sama seperti sidebar desktop di web.
class AdminSidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  const AdminSidebar(
      {super.key, required this.selected, required this.onSelect, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        border: Border(right: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
      ),
      child: Column(
        children: [
          Padding(
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
                      Text('Panel Admin',
                          style: TextStyle(
                              fontSize: 10, color: dark ? Colors.white54 : ZK.slate500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _AdminMenuList(selected: selected, onSelect: onSelect, onLogout: onLogout)),
        ],
      ),
    );
  }
}

// Isi daftar menu (dipakai Drawer ponsel maupun sidebar tablet) supaya
// grouping & styling-nya persis sama di kedua mode.
class _AdminMenuList extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  const _AdminMenuList({required this.selected, required this.onSelect, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    var i = 0;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final g in _groups) ...[
                if (g.label != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(g.label!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: dark ? Colors.white38 : ZK.slate400)),
                  ),
                for (final it in g.items) _item(context, it, i++, dark),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: toggleThemeMode,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: dark ? Colors.white70 : ZK.slate600,
                        side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                    child: const Icon(Icons.logout, size: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, _NavItem it, int index, bool dark) {
    final active = index == selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r12,
          onTap: () => onSelect(index),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: active ? ZK.primary : null, borderRadius: r12),
            child: Row(
              children: [
                Icon(it.icon,
                    size: 19, color: active ? Colors.white : (dark ? Colors.white60 : ZK.slate600)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(it.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate600))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder untuk menu yang belum dibangun — jelas namanya, bukan error
// diam-diam, supaya kelihatan ini memang belum ada isinya (bukan bug).
class _ComingSoonPage extends StatelessWidget {
  final _NavItem item;
  const _ComingSoonPage({required this.item});
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        bottom: false,
        child: EmptyState(
          icon: item.icon,
          title: item.title,
          description: 'Menu ini sedang disiapkan dan akan segera hadir.',
        ),
      );
}

// Dashboard admin: sapaan + jalan pintas ke semua menu (dikelompokkan sama
// seperti sidebar) — belum ada analitik nyata sampai endpoint admin
// tersedia, jadi fase ini fokus jadi hub navigasi yang jujur (bukan data
// palsu).
const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String _formatTanggal(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_bulanPanjang[d.month - 1]} ${d.year}';
}

// Dashboard admin — isinya disamakan persis dengan src/app/admin/dashboard/page.tsx
// di web (FinanceDashboard): 4 stat utama, angka pendukung, grafik omzet &
// laba tahun berjalan, stok menipis, produk terlaris, transaksi terbaru.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  DashboardSummary? _summary;
  List<ChartBulan> _chart = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait(
          [Api.dashboardSummary(), Api.dashboardChart(DateTime.now().year)]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as DashboardSummary;
        _chart = results[1] as List<ChartBulan>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate500;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: ZK.primary));
    }
    final s = _summary;
    if (_error != null || s == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Gagal memuat dashboard',
                  textAlign: TextAlign.center, style: TextStyle(color: fg)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    final tablet = isTablet(context);
    // Tablet: gap & padding kartu sedikit dipadatkan, dan bagian yang di web
    // berdampingan (chart+stok, terlaris+transaksi) juga dibikin sebaris di
    // sini — supaya informasi yang kelihatan pertama kali lebih banyak,
    // bukan cuma numpuk ke bawah seperti ponsel.
    final gap = tablet ? 10.0 : 14.0;
    final pad = tablet ? 12.0 : 14.0;

    // Tablet: Row of Expanded, bukan GridView beraspek-rasio tetap — grid
    // dengan childAspectRatio bikin sel jauh lebih tinggi dari kontennya di
    // layar lebar (itu sumber ruang kosong besar yang dikeluhkan), Row
    // otomatis setinggi konten.
    final statGrid = tablet
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _statCard('Omzet hari ini (tanpa PPN)', rupiah(s.pendapatanHariIni),
                    Icons.shopping_bag_outlined, ZK.brand700, dark)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Transaksi hari ini', '${s.transaksiHariIni}',
                    Icons.receipt_long_outlined, ZK.primary, dark)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Laba kotor hari ini', rupiah(s.labaHariIni),
                    Icons.trending_up, ZK.amber700, dark)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Stok menipis', '${s.stokMenipis.length}',
                    Icons.warning_amber_outlined, ZK.rose, dark)),
              ],
            ),
          )
        : GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCard('Omzet hari ini (tanpa PPN)', rupiah(s.pendapatanHariIni),
                  Icons.shopping_bag_outlined, ZK.brand700, dark),
              _statCard('Transaksi hari ini', '${s.transaksiHariIni}',
                  Icons.receipt_long_outlined, ZK.primary, dark),
              _statCard('Laba kotor hari ini', rupiah(s.labaHariIni),
                  Icons.trending_up, ZK.amber700, dark),
              _statCard('Stok menipis', '${s.stokMenipis.length}',
                  Icons.warning_amber_outlined, ZK.rose, dark),
            ],
          );

    final supportRow = tablet
        ? Row(
            children: [
              Expanded(child: _supportStat('Total diterima (bruto)', rupiah(s.totalDibayarHariIni), fg, muted)),
              Expanded(child: _supportStat('PPN terkumpul', rupiah(s.ppnHariIni), fg, muted)),
              Expanded(child: _supportStat('Service charge', rupiah(s.serviceHariIni), fg, muted)),
              Expanded(child: _supportStat('Rata-rata / transaksi', rupiah(s.rataRataTransaksi), fg, muted)),
            ],
          )
        : GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _supportStat('Total diterima (bruto)', rupiah(s.totalDibayarHariIni), fg, muted),
              _supportStat('PPN terkumpul', rupiah(s.ppnHariIni), fg, muted),
              _supportStat('Service charge', rupiah(s.serviceHariIni), fg, muted),
              _supportStat('Rata-rata / transaksi', rupiah(s.rataRataTransaksi), fg, muted),
            ],
          );

    final supportCard = _card(dark, child: Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          supportRow,
          const SizedBox(height: 8),
          Text(
              'Omzet = penjualan bersih (tanpa PPN & service). PPN adalah titipan pajak, bukan pendapatan.',
              style: TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    ));

    final chartCard = _card(dark, child: Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Omzet & Laba ${DateTime.now().year}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 2),
          Text('Performa penjualan bulanan.', style: TextStyle(fontSize: 12, color: muted)),
          SizedBox(height: tablet ? 8 : 14),
          _yearChart(_chart, dark, fg, muted, tablet),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(ZK.primary, 'Omzet', fg),
              const SizedBox(width: 16),
              _legend(ZK.amber700, 'Laba', fg),
            ],
          ),
        ],
      ),
    ));

    final stokCard = _card(dark, child: Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produk stok menipis',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 2),
          Text('Prioritaskan restock sebelum transaksi ramai.',
              style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          if (s.stokMenipis.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                  color: dark ? ZK.primary.withValues(alpha: 0.12) : ZK.brand50,
                  borderRadius: r12),
              child: Text('Semua stok aman',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.greenAccent : const Color(0xFF047857))),
            )
          else
            for (final p in s.stokMenipis) _row(dark,
                left: p.nama,
                right: _badge('${p.stok}', p.stok <= 0 ? ZK.rose : ZK.amber700)),
        ],
      ),
    ));

    final terlarisCard = _card(dark, child: Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star, size: 16, color: ZK.amber700),
            const SizedBox(width: 6),
            Text('Produk terlaris bulan ini',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
          ]),
          const SizedBox(height: 2),
          Text('5 produk dengan penjualan terbanyak.',
              style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          if (s.produkTerlaris.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada penjualan bulan ini',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: muted)),
            )
          else
            for (var i = 0; i < s.produkTerlaris.length; i++)
              _row(dark,
                  leading: CircleAvatar(
                      radius: 11,
                      backgroundColor: ZK.brand50,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800, color: ZK.primary))),
                  left: s.produkTerlaris[i].nama,
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${s.produkTerlaris[i].qty} terjual',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
                      Text(rupiah(s.produkTerlaris[i].omzet),
                          style: TextStyle(fontSize: 11, color: muted)),
                    ],
                  )),
        ],
      ),
    ));

    final transaksiCard = _card(dark, child: Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long, size: 16, color: ZK.primary),
            const SizedBox(width: 6),
            Text('Transaksi terbaru',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
          ]),
          const SizedBox(height: 2),
          Text('5 transaksi terakhir.', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          if (s.transaksiTerbaru.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada transaksi',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: muted)),
            )
          else
            for (final t in s.transaksiTerbaru)
              _row(dark,
                  left: t.label,
                  leftSub:
                      '${t.namaKasir ?? '-'} · ${t.tanggal ?? '-'}, ${(t.jam ?? '').length >= 5 ? t.jam!.substring(0, 5) : t.jam ?? ''}',
                  right: Text(rupiah(t.total),
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: fg))),
        ],
      ),
    ));

    return SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        color: ZK.primary,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, tablet ? 16 : 24),
          children: [
            Text('Ringkasan operasional toko',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 2),
            Text(_formatTanggal(s.tanggal), style: TextStyle(fontSize: 12.5, color: muted)),
            SizedBox(height: gap),
            statGrid,
            SizedBox(height: gap),
            supportCard,
            SizedBox(height: gap),
            if (tablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: chartCard),
                  SizedBox(width: gap),
                  Expanded(child: stokCard),
                ],
              )
            else ...[
              chartCard,
              const SizedBox(height: 14),
              stokCard,
            ],
            SizedBox(height: gap),
            if (tablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: terlarisCard),
                  SizedBox(width: gap),
                  Expanded(child: transaksiCard),
                ],
              )
            else ...[
              terlarisCard,
              const SizedBox(height: 14),
              transaksiCard,
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(bool dark, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: child,
      );

  Widget _statCard(String label, String value, IconData icon, Color tone, bool dark) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: tone),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : ZK.ink)),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: dark ? Colors.white60 : ZK.slate500)),
          ],
        ),
      );

  Widget _supportStat(String label, String value, Color fg, Color muted) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: muted)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
        ],
      );

  Widget _legend(Color color, String label, Color fg) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: fg)),
        ],
      );

  Widget _badge(String text, Color tone) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: tone.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: tone)),
      );

  Widget _row(bool dark, {Widget? leading, required String left, String? leftSub, required Widget right}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: r12,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 8)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : ZK.slate600)),
                  if (leftSub != null)
                    Text(leftSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: dark ? Colors.white54 : ZK.slate400)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            right,
          ],
        ),
      );

  Widget _yearChart(List<ChartBulan> data, bool dark, Color fg, Color muted, bool tablet) {
    final byBulan = {for (final c in data) c.bulan: c};
    final maxVal = data.fold<int>(1, (m, c) => [m, c.omzet, c.laba].reduce((a, b) => a > b ? a : b));
    final barMax = tablet ? 90.0 : 130.0;
    return SizedBox(
      height: tablet ? 120 : 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var m = 1; m <= 12; m++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar((byBulan[m]?.omzet ?? 0) / maxVal, ZK.primary, barMax),
                        const SizedBox(width: 2),
                        _bar((byBulan[m]?.laba ?? 0) / maxVal, ZK.amber700, barMax),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_bulanPendek[m - 1],
                        style: TextStyle(fontSize: 9, color: muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(double ratio, Color color, double maxHeight) => Container(
        width: 5,
        height: (ratio.clamp(0, 1) * maxHeight) + 2,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      );
}
