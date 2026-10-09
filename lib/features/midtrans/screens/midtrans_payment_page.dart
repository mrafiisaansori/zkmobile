import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

const _finalStatus = {'PAID', 'FAILED', 'EXPIRED', 'CANCELLED'};

// Halaman Snap Midtrans dimuat di WebView in-app (bukan browser eksternal) —
// status dipoll ke backend tiap beberapa detik; backend query ulang ke
// Midtrans kalau belum final, jadi tidak perlu urus deep-link/callback URL.
// Padanan _MidtransPaymentPageState lama — cukup logika sederhana (poll +
// webview), tidak perlu cubit terpisah.
class MidtransPaymentPage extends StatefulWidget {
  final int paymentId;
  final String snapUrl;
  const MidtransPaymentPage({super.key, required this.paymentId, required this.snapUrl});
  @override
  State<MidtransPaymentPage> createState() => _MidtransPaymentPageState();
}

class _MidtransPaymentPageState extends State<MidtransPaymentPage> {
  late final _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      onPageStarted: (_) => setState(() => _loading = true),
      onPageFinished: (_) => setState(() => _loading = false),
    ))
    ..loadRequest(Uri.parse(widget.snapUrl));
  bool _loading = true, _saving = false, _cancelling = false;
  Timer? _poll;
  final _shotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final d = await apiGet('/subscription/payment/${widget.paymentId}/status') as Map<String, dynamic>;
      final p = SubscriptionPayment.fromJson(d);
      if (!mounted) return;
      if (_finalStatus.contains(p.status)) {
        _poll?.cancel();
        Navigator.of(context).pop(p.status);
      }
    } catch (_) {
      // Koneksi putus sesaat — coba lagi di tick berikutnya, jangan tutup halaman.
    }
  }

  // Snap Midtrans render QRIS-nya sebagai gambar di dalam halamannya sendiri
  // (beda origin, tidak bisa diambil URL-nya langsung) — jadi cara paling
  // sederhana & pasti berhasil adalah screenshot area WebView-nya lalu
  // simpan ke galeri, apa pun metode bayar yang lagi ditampilkan.
  Future<void> _simpanTangkapan() async {
    setState(() => _saving = true);
    try {
      final boundary =
          _shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Halaman belum siap');
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('Gagal mengambil gambar');
      await Gal.putImageBytes(bytes.buffer.asUint8List(), name: 'zonakasir_qris');
      if (mounted) toastOk(context, 'Gambar disimpan ke galeri');
    } catch (e) {
      if (mounted) toastError(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Padanan tombol "Batalkan Pembayaran" di web (langsung batal, tanpa
  // dialog konfirmasi tambahan — beda dari tombol close/back yang memang
  // sengaja dikonfirmasi karena bisa ketutup tidak sengaja).
  Future<void> _batalkan() async {
    setState(() => _cancelling = true);
    try {
      await apiPost('/subscription/payment/${widget.paymentId}/cancel');
      if (!mounted) return;
      toastOk(context, 'Pembayaran dibatalkan');
      Navigator.of(context).pop('CANCELLED');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<bool> _confirmClose() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan pembayaran?'),
        content: const Text('Kalau sudah bayar, tunggu sebentar. Status akan terupdate otomatis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tetap di sini')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tutup')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          appBar: AppBar(
            backgroundColor: ZK.primary,
            foregroundColor: Colors.white,
            title: const Text('Pembayaran'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (await _confirmClose() && mounted) navigator.pop(null);
              },
            ),
            actions: [
              IconButton(
                tooltip: 'Simpan QRIS / tangkapan halaman',
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_outlined),
                onPressed: _saving ? null : _simpanTangkapan,
              ),
            ],
          ),
          body: RepaintBoundary(
            key: _shotKey,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const Center(child: CircularProgressIndicator(color: ZK.primary)),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 46,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelling ? null : _batalkan,
                  icon: _cancelling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ZK.rose))
                      : const Icon(Icons.block, size: 18, color: ZK.rose),
                  label: const Text('Batalkan Pembayaran',
                      style: TextStyle(color: ZK.rose, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ZK.rose200),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                ),
              ),
            ),
          ),
        );
}
