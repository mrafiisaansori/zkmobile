import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import 'toast.dart';

// Error jaringan mentah (SocketException dsb) tampil jelek & teknis —
// diseragamkan jadi satu pesan yang manusiawi, dari satu tempat ini saja
// biar konsisten di semua halaman (dashboard, riwayat, POS, dst).
void toastError(BuildContext ctx, Object e) => showAppToast(
    ctx,
    e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e'),
    ToastKind.error);
void toastOk(BuildContext ctx, String text) =>
    showAppToast(ctx, text, ToastKind.success);
