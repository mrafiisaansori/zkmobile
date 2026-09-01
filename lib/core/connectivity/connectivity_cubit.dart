import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Status koneksi real-time (interface WiFi/data, bukan jaminan internet
// beneran nyampe) — dipakai buat banner "Sedang offline" yang selalu
// terlihat. Keputusan APAKAH suatu transaksi berhasil/gagal tetap dari
// hasil panggilan API sebenarnya (lihat core/network/api_client.dart
// isNetworkError), ini cuma indikator visual proaktif.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit() : super(false);

  void start() {
    Connectivity().checkConnectivity().then(_update);
    Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    emit(results.every((r) => r == ConnectivityResult.none));
  }
}
