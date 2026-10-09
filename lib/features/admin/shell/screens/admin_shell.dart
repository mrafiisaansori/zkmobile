import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/screens/login_page.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../dashboard/screens/admin_dashboard_page.dart';
import '../../katalog/screens/admin_katalog_page.dart';
import '../../kategori/screens/admin_kategori_page.dart';
import '../../keuangan/screens/admin_keuangan_page.dart';
import '../../langganan/screens/admin_langganan_page.dart';
import '../../laporan_closing/screens/admin_closing_page.dart';
import '../../member/screens/admin_member_page.dart';
import '../../pembelian/screens/admin_pembelian_page.dart';
import '../../pengaturan/screens/admin_pengaturan_page.dart';
import '../../pengguna/screens/admin_pengguna_page.dart';
import '../../produk/screens/admin_produk_page.dart';
import '../../retur/screens/admin_retur_page.dart';
import '../../satuan/screens/admin_satuan_page.dart';
import '../../stok/screens/admin_stok_page.dart';
import '../../supplier/screens/admin_supplier_page.dart';
import '../../transaksi/screens/admin_transaksi_page.dart';
import '../../varian/screens/admin_varian_page.dart';
import '../../voucher/screens/admin_voucher_page.dart';
import '../cubit/admin_shell_cubit.dart';
import '../widgets/admin_sidebar.dart';

// Shell untuk role admin (back-office, tanpa akses jual/POS) — padanan
// src/constants/nav.ts bagian admin di web. Semua 18 menu sudah terisi.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AdminShellCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AdminShellCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _select(int i) {
    _cubit.select(i);
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
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AdminShellCubit, int>(
        builder: (context, index) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final item = flatNavItems[index];
          final content = switch (index) {
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
            // Ke-18 menu sudah terpetakan; indeks lain tidak mungkin terjadi.
            _ => const AdminDashboardPage(),
          };
          final hero = HeroShell(
            titleOverride: item.title,
            subtitleOverride: 'Menu admin',
            onMenuTap:
                isTablet(context) ? null : () => _scaffoldKey.currentState?.openDrawer(),
            child: content,
          );

          if (isTablet(context)) {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: dark ? ZK.bgDark : ZK.background,
              body: Row(
                children: [
                  AdminSidebar(selected: index, onSelect: _select, onLogout: _logout),
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
              // sidebar tablet yang punya logo di atas) — kasih SafeArea +
              // jarak supaya item pertama tidak mepet ke atas layar.
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AdminMenuList(selected: index, onSelect: _select, onLogout: _logout),
                ),
              ),
            ),
            body: hero,
          );
        },
      ),
    );
  }
}
