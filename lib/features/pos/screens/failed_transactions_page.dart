import 'package:flutter/material.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

// Daftar persisten transaksi offline yang gagal disinkron (ditolak server,
// mis. stok tidak cukup) — supaya tidak "mengambang" cuma lewat lewat toast
// sekali, dan bisa ditinjau/dicoba lagi manual (mis. setelah admin sesuaikan
// stok). Transaksi yang masih menunggu koneksi (belum pernah dicoba kirim)
// juga ditampilkan supaya kasir tahu apa saja yang masih tertahan.
class FailedTransactionsPage extends StatefulWidget {
  const FailedTransactionsPage({super.key});
  @override
  State<FailedTransactionsPage> createState() => _FailedTransactionsPageState();
}

class _FailedTransactionsPageState extends State<FailedTransactionsPage> {
  List<QueuedSale> _queue = [];
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final q = await getOfflineQueue();
    if (mounted) {
      setState(() {
        _queue = q;
        _loading = false;
      });
    }
  }

  Future<void> _retry(QueuedSale item) async {
    setState(() => _busy.add(item.localId));
    await retryQueueItem(item.localId);
    final r = await flushOfflineQueue();
    if (!mounted) return;
    setState(() => _busy.remove(item.localId));
    if (r.synced > 0) {
      toastOk(context, 'Berhasil disinkron');
    } else if (r.failed > 0) {
      toastError(context, 'Masih ditolak server: cek lagi keterangannya');
    } else {
      toastError(context, 'Belum ada koneksi internet');
    }
    _load();
  }

  Future<void> _hapus(QueuedSale item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus transaksi ini?',
        message:
            'Transaksi "${item.label}" akan dihapus permanen dari antrean dan TIDAK akan pernah dikirim ke server. Pastikan sudah dicatat manual kalau perlu.',
        danger: true);
    if (!ok) return;
    await removeFromQueue(item.localId);
    if (mounted) toastOk(context, 'Dihapus dari antrean');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate600;
    final cardColor = dark ? ZK.cardDark : Colors.white;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    final failed = _queue.where((q) => q.status == 'failed').toList();
    final pending = _queue.where((q) => q.status != 'failed').toList();

    return Scaffold(
      backgroundColor: dark ? ZK.bgDark : ZK.background,
      body: HeroShell(
        compact: true,
        child: SafeArea(
          top: false,
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: ZK.primary))
              : RefreshIndicator(
                  color: ZK.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: r12,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 18, color: fg),
                              const SizedBox(width: 6),
                              Text('Kembali',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Transaksi Bermasalah',
                          style:
                              TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
                      const SizedBox(height: 4),
                      Text(
                          'Transaksi offline yang ditolak server atau masih menunggu koneksi.',
                          style: TextStyle(fontSize: 13, color: muted)),
                      const SizedBox(height: 18),
                      if (_queue.isEmpty)
                        const EmptyState(
                            icon: Icons.task_alt,
                            title: 'Tidak ada yang bermasalah',
                            description: 'Semua transaksi offline sudah tersinkron.'),
                      if (failed.isNotEmpty) ...[
                        Text('Ditolak server (${failed.length})',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800, color: ZK.rose)),
                        const SizedBox(height: 8),
                        for (final item in failed)
                          _card(item, fg, muted, cardColor, lineColor, rejected: true),
                        const SizedBox(height: 18),
                      ],
                      if (pending.isNotEmpty) ...[
                        Text('Menunggu koneksi (${pending.length})',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800, color: ZK.amber700)),
                        const SizedBox(height: 8),
                        for (final item in pending)
                          _card(item, fg, muted, cardColor, lineColor, rejected: false),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _card(QueuedSale item, Color fg, Color muted, Color cardColor, Color lineColor,
      {required bool rejected}) {
    final busy = _busy.contains(item.localId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: r14,
        border: Border.all(color: rejected ? ZK.rose.withValues(alpha: 0.3) : lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(rejected ? Icons.error_outline : Icons.cloud_off,
                  size: 18, color: rejected ? ZK.rose : ZK.amber700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
              ),
            ],
          ),
          if (item.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(item.errorMessage!, style: const TextStyle(fontSize: 12, color: ZK.rose)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _retry(item),
                    icon: busy
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 16),
                    label: const Text('Coba lagi', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: ZK.primary,
                        side: const BorderSide(color: ZK.brand200),
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                  ),
                ),
              ),
              if (rejected) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _hapus(item),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: ZK.rose,
                        side: const BorderSide(color: ZK.rose200),
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                    child: const Icon(Icons.delete_outline, size: 16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
