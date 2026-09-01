import 'package:audioplayers/audioplayers.dart';

// Nada sukses pendek (dua nada naik) untuk feedback transaksi selesai.
final _player = AudioPlayer();

Future<void> playSuccessSound() async {
  try {
    await _player.play(AssetSource('success.mp3'));
  } catch (_) {
    // Jangan sampai gagal main suara mengganggu alur transaksi.
  }
}
