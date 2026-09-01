import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

// Antrean transaksi (checkout biasa maupun bayar open bill) yang gagal
// terkirim karena koneksi putus (bukan ditolak server) — padanan
// src/utils/offlineQueue.ts di web. Disimpan di SharedPreferences supaya
// bertahan lewat restart app, lalu dikirim ulang otomatis begitu online lagi.
class QueuedSale {
  final String localId;
  final String endpoint;
  final Map<String, dynamic> body;
  final String label; // ringkasan buat ditampilkan, mis. "Rp50.000 · 3 item"
  final String createdAt;
  String status; // pending | failed
  String? errorMessage;
  QueuedSale({
    required this.localId,
    required this.endpoint,
    required this.body,
    required this.label,
    required this.createdAt,
    this.status = 'pending',
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'endpoint': endpoint,
        'body': body,
        'label': label,
        'createdAt': createdAt,
        'status': status,
        'errorMessage': errorMessage,
      };

  factory QueuedSale.fromJson(Map<String, dynamic> j) => QueuedSale(
        localId: '${j['localId']}',
        endpoint: '${j['endpoint'] ?? '/penjualan/checkout'}',
        body: Map<String, dynamic>.from(j['body'] as Map),
        label: '${j['label'] ?? ''}',
        createdAt: '${j['createdAt'] ?? ''}',
        status: '${j['status'] ?? 'pending'}',
        errorMessage: j['errorMessage'] as String?,
      );
}

const _key = 'zk_offline_sales_queue';

Future<List<QueuedSale>> _readQueue() async {
  final sp = await SharedPreferences.getInstance();
  final raw = sp.getString(_key);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => QueuedSale.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> _writeQueue(List<QueuedSale> q) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(_key, jsonEncode(q.map((e) => e.toJson()).toList()));
}

Future<List<QueuedSale>> getOfflineQueue() => _readQueue();

Future<void> enqueueOfflineSale(String endpoint, Map<String, dynamic> body, String label) async {
  final q = await _readQueue();
  q.add(QueuedSale(
    localId: DateTime.now().millisecondsSinceEpoch.toString(),
    endpoint: endpoint,
    body: body,
    label: label,
    createdAt: DateTime.now().toIso8601String(),
  ));
  await _writeQueue(q);
}

Future<void> removeFromQueue(String localId) async {
  final q = await _readQueue();
  q.removeWhere((e) => e.localId == localId);
  await _writeQueue(q);
}

// Set 'failed' balik jadi 'pending' supaya dicoba lagi di flush berikutnya
// (dipakai tombol "Coba lagi" manual, mis. setelah admin nambah stok).
Future<void> retryQueueItem(String localId) async {
  final q = await _readQueue();
  for (final item in q) {
    if (item.localId == localId) {
      item.status = 'pending';
      item.errorMessage = null;
    }
  }
  await _writeQueue(q);
}

class FlushResult {
  final int synced, failed;
  FlushResult(this.synced, this.failed);
}

// Kirim ulang semua yang pending. Yang ditolak server (bukan soal koneksi)
// ditandai 'failed' dan tidak diulang otomatis lagi — supaya kelihatan dan
// bisa ditinjau manual, bukan nyangkut retry selamanya.
Future<FlushResult> flushOfflineQueue() async {
  final queue = await _readQueue();
  var synced = 0, failed = 0;
  final remaining = <QueuedSale>[];
  for (final item in queue) {
    if (item.status == 'failed') {
      remaining.add(item);
      continue;
    }
    try {
      await apiPost(item.endpoint, item.body);
      synced++;
    } catch (e) {
      if (isNetworkError(e)) {
        remaining.add(item);
      } else {
        item.status = 'failed';
        item.errorMessage = '$e';
        failed++;
        remaining.add(item);
      }
    }
  }
  await _writeQueue(remaining);
  return FlushResult(synced, failed);
}
