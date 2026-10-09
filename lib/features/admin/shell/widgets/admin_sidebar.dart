import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';

// Padanan _NavItem/_NavGroup di admin_shell.dart lama — daftar menu admin
// dikelompokkan Master Data/Operasional/Laporan/Lainnya. Publik (bukan
// private) karena dipakai bareng oleh AdminSidebar (tablet) DAN AdminShell
// (Drawer ponsel) di file screens/admin_shell.dart.
class NavItem {
  final String title;
  final IconData icon;
  const NavItem(this.title, this.icon);
}

class NavGroup {
  final String? label;
  final List<NavItem> items;
  const NavGroup(this.label, this.items);
}

const navGroups = [
  NavGroup(null, [NavItem('Dashboard', Icons.dashboard_outlined)]),
  NavGroup('Master Data', [
    NavItem('Kategori', Icons.sell_outlined),
    NavItem('Satuan', Icons.straighten_outlined),
    NavItem('Varian', Icons.layers_outlined),
    NavItem('Produk', Icons.inventory_2_outlined),
    NavItem('Supplier', Icons.local_shipping_outlined),
    NavItem('Member', Icons.people_outline),
    NavItem('Pengguna', Icons.manage_accounts_outlined),
    NavItem('Voucher', Icons.confirmation_number_outlined),
  ]),
  NavGroup('Operasional', [
    NavItem('Stok Opname', Icons.inventory_outlined),
    NavItem('Pembelian Barang', Icons.shopping_cart_outlined),
    NavItem('Retur Barang', Icons.assignment_return_outlined),
    NavItem('Katalog', Icons.storefront_outlined),
  ]),
  NavGroup('Laporan', [
    NavItem('Laporan Transaksi', Icons.receipt_long_outlined),
    NavItem('Laporan Keuangan', Icons.bar_chart_outlined),
    NavItem('Laporan Closing', Icons.fact_check_outlined),
  ]),
  NavGroup('Lainnya', [
    NavItem('Pengaturan', Icons.settings_outlined),
    NavItem('Langganan', Icons.workspace_premium_outlined),
  ]),
];

final List<NavItem> flatNavItems = [for (final g in navGroups) ...g.items];

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
                              fontSize: 10, color: dark ? Colors.white60 : ZK.slate500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: AdminMenuList(selected: selected, onSelect: onSelect, onLogout: onLogout)),
        ],
      ),
    );
  }
}

// Isi daftar menu (dipakai Drawer ponsel maupun sidebar tablet) supaya
// grouping & styling-nya persis sama di kedua mode.
class AdminMenuList extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  const AdminMenuList(
      {super.key, required this.selected, required this.onSelect, required this.onLogout});

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
              for (final g in navGroups) ...[
                if (g.label != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(g.label!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: dark ? Colors.white60 : ZK.slate500)),
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
                    onPressed: () => context.read<ThemeCubit>().toggle(),
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

  Widget _item(BuildContext context, NavItem it, int index, bool dark) {
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
