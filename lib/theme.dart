import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Palet Zona Kasir — disalin dari tailwind.config.ts agar identik dengan web.
class ZK {
  static const brand50 = Color(0xFFEEF6FB);
  static const brand100 = Color(0xFFD6EBF5);
  static const brand200 = Color(0xFFB3DCEB);
  static const brand700 = Color(0xFF055E9C);
  static const primary = Color(0xFF0A6CB0);
  static const accent = Color(0xFF00A3CC);
  static const background = Color(0xFFF6F8FA);
  static const ink = Color(0xFF0A2540);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE6EBF0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  // Dipakai untuk teks sekunder di bawah 13px (hint, sublabel, jam) —
  // slate500 kurang kontras di ukuran kecil, ini lebih gelap agar tetap AA.
  static const slate600 = Color(0xFF475569);
  static const slate900 = Color(0xFF0F172A);
  static const rose = Color(0xFFE11D48);
  static const rose50 = Color(0xFFFFF1F2);
  static const amber50 = Color(0xFFFFFBEB);
  static const amber700 = Color(0xFFB45309);
  // Dark mode
  static const bgDark = Color(0xFF0B1220);
  static const cardDark = Color(0xFF121C30);
  static const lineDark = Color(0xFF223049);
}

final zkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: ZK.background,
  colorScheme: ColorScheme.fromSeed(seedColor: ZK.primary, primary: ZK.primary),
  fontFamily: 'Roboto',
);

final zkDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ZK.bgDark,
  colorScheme: ColorScheme.fromSeed(
      seedColor: ZK.primary, brightness: Brightness.dark, primary: ZK.accent),
  fontFamily: 'Roboto',
);

// Preferensi tema global — dipakai lewat toggle di header & login.
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> loadThemeMode() async {
  final sp = await SharedPreferences.getInstance();
  themeMode.value = sp.getString('theme_mode') == 'dark' ? ThemeMode.dark : ThemeMode.light;
}

Future<void> toggleThemeMode() async {
  themeMode.value =
      themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  final sp = await SharedPreferences.getInstance();
  await sp.setString(
      'theme_mode', themeMode.value == ThemeMode.dark ? 'dark' : 'light');
}

// Breakpoint tunggal buat semua layout tablet-vs-ponsel di app ini.
bool isTablet(BuildContext c) => MediaQuery.of(c).size.shortestSide >= 600;

// Judul+subjudul per tab shell, buat header tablet (HeroShell butuh tahu
// halaman aktif tanpa tiap page harus mengoper title-nya sendiri).
// Diupdate oleh KasirShellState.goTo(), dibaca oleh HeroShell.
final activeTab = ValueNotifier<int>(0);
const tabTitles = [
  ('Dashboard', 'Ringkasan performa bisnis Anda'),
  ('Kasir', 'Kelola transaksi penjualan'),
  ('Open Bill', 'Kelola tagihan tertunda'),
  ('Buka/Tutup Kas', 'Kelola sesi kasir'),
  ('Riwayat', 'Riwayat transaksi penjualan'),
];

// Radius web: 2xl = 12px, 3xl = 14px, pill sheet = 28px.
const r12 = BorderRadius.all(Radius.circular(12));
const r14 = BorderRadius.all(Radius.circular(14));

// Masking titik ribuan untuk input nominal (mis. "150.000") — dipakai di
// semua field uang: bayar, modal awal, mutasi kas, tutup kasir.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
      b.write(digits[i]);
    }
    final text = b.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

// Baca angka murni dari field yang dimasking RupiahInputFormatter.
int parseRupiah(String s) => int.tryParse(s.replaceAll('.', '')) ?? 0;
