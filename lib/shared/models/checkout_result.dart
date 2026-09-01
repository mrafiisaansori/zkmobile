import '_util.dart';

class CheckoutResult {
  final int id, total, bayar, kembalian, remainingTotal;
  final String noNota, billStatus;
  final bool offline;
  CheckoutResult.fromJson(Map<String, dynamic> j)
      : id = i(j['id']),
        noNota = '${j['no_nota'] ?? ''}',
        total = i(j['total']),
        bayar = i(j['bayar']),
        kembalian = i(j['kembalian']),
        remainingTotal = i(j['remaining_total']),
        billStatus = '${j['bill_status'] ?? ''}',
        offline = false;

  // Draft lokal saat checkout gagal karena koneksi putus — belum tersinkron
  // server, no_nota "OFFLINE-xxxxxx" sampai antrean berhasil dikirim ulang.
  CheckoutResult.offlineDraft({
    required this.total,
    required this.bayar,
  })  : id = -DateTime.now().millisecondsSinceEpoch,
        noNota = 'OFFLINE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        kembalian = bayar - total,
        remainingTotal = 0,
        billStatus = '',
        offline = true;
}
