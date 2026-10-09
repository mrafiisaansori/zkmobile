import 'package:flutter/material.dart';

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
  // onPrimary putih: semua FilledButton memakai latar biru (ZK.primary),
  // onPrimary bawaan seed gelap bikin labelnya tak terbaca di mode gelap.
  colorScheme: ColorScheme.fromSeed(
      seedColor: ZK.primary, brightness: Brightness.dark, primary: ZK.accent, onPrimary: Colors.white),
  fontFamily: 'Roboto',
);

// Breakpoint tunggal buat semua layout tablet-vs-ponsel di app ini.
bool isTablet(BuildContext c) => MediaQuery.of(c).size.shortestSide >= 600;

// Radius web: 2xl = 12px, 3xl = 14px, pill sheet = 28px.
const r12 = BorderRadius.all(Radius.circular(12));
const r14 = BorderRadius.all(Radius.circular(14));
