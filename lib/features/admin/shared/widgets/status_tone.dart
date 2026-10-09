import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Status dokumen Pembelian/Retur: 0=Draft, 1=Selesai, 2=Dibatalkan — sama
// persis dengan _statusLabel/statusTone di lib/admin_pembelian_page.dart lama
// (retur mengimpor statusTone dari sana via `show`). Ditaruh di shared/
// karena dipakai kedua entity.
const statusLabel = {0: 'Draft', 1: 'Selesai', 2: 'Dibatalkan'};

(Color, Color) statusTone(int status, bool dark) => switch (status) {
      1 => (softBg(ZK.success, ZK.successBg, dark), okTone(dark)),
      2 => (softBg(ZK.rose, ZK.rose50, dark), ZK.rose),
      _ => (softBg(ZK.amber700, ZK.amber50, dark), ZK.amber700),
    };
