import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// Status koneksi real-time (interface WiFi/data, bukan jaminan internet
// beneran nyampe) — dipakai buat banner "Sedang offline" yang selalu
// terlihat. Keputusan APAKAH suatu transaksi berhasil/gagal tetap dari
// hasil panggilan API sebenarnya (lihat api.dart isNetworkError), ini
// cuma indikator visual proaktif.
final isOffline = ValueNotifier<bool>(false);

void initConnectivityWatcher() {
  Connectivity().checkConnectivity().then(_update);
  Connectivity().onConnectivityChanged.listen(_update);
}

void _update(List<ConnectivityResult> results) {
  isOffline.value = results.every((r) => r == ConnectivityResult.none);
}
