import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Status dokumen Pembelian/Retur: 0=Draft, 1=Selesai, 2=Dibatalkan — sama
// persis dengan _statusLabel/statusTone di lib/admin_pembelian_page.dart lama
// (retur mengimpor statusTone dari sana via `show`). Ditaruh di shared/
// karena dipakai kedua entity.
const statusLabel = {0: 'Draft', 1: 'Selesai', 2: 'Dibatalkan'};

(Color, Color) statusTone(int status, bool dark) => switch (status) {
      1 => (dark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
          dark ? Colors.greenAccent : const Color(0xFF047857)),
      2 => (ZK.rose50, ZK.rose),
      _ => (ZK.amber50, ZK.amber700),
    };
