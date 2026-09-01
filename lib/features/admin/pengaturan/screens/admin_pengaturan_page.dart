import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/pajak_tab.dart';
import '../widgets/pembayaran_tab.dart';
import '../widgets/toko_tab.dart';

// Padanan src/app/admin/pengaturan/{page,pajak,pembayaran}.tsx — 3 sub-area
// web (identitas toko, pajak, QRIS) digabung jadi 3 tab di satu halaman
// mobile, dihubungkan lewat SettingsTabs di web.
class AdminPengaturanPage extends StatefulWidget {
  const AdminPengaturanPage({super.key});
  @override
  State<AdminPengaturanPage> createState() => _AdminPengaturanPageState();
}

class _AdminPengaturanPageState extends State<AdminPengaturanPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                _tabChip('Toko', 0, dark),
                const SizedBox(width: 8),
                _tabChip('Pajak', 1, dark),
                const SizedBox(width: 8),
                _tabChip('Pembayaran', 2, dark),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [TokoTab(), PajakTab(), PembayaranTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int i, bool dark) {
    final active = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
            borderRadius: r12,
            border: Border.all(color: active ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
        ),
      ),
    );
  }
}
