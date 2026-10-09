import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../shared/models/models.dart';
import '../data/pos_repository.dart';
import '../models/bill_context.dart';
import '../models/cart_item.dart';
import 'checkout_state.dart';

// Hasil simpan open bill: tersimpan langsung ke server, atau diantre lokal
// karena koneksi putus (padanan dua cabang try/catch _saveBill lama).
enum BillSaveResult { saved, offline }

// Padanan separuh "transaksi" dari PosPageState lama: checkout/bayar bill,
// simpan/ubah/batalkan open bill, split bill, + integrasi antrean offline
// (enqueueOfflineSale/flushOfflineQueue). Tidak menyentuh CartCubit secara
// langsung — pemanggil (PosPage/sheets) yang membaca CartCubit.state sebagai
// parameter lalu memutuskan cara membersihkan/memuat ulang keranjang setelah
// hasilnya diketahui, supaya cubit ini tetap gampang diuji tanpa BuildContext.
class CheckoutCubit extends Cubit<CheckoutState> {
  final PosRepository _repo;
  CheckoutCubit({PosRepository? repository})
      : _repo = repository ?? PosRepository(),
        super(const CheckoutState());

  // Ringkasan produk buat ditampilkan di antrean/halaman Transaksi
  // Bermasalah, mis. "Nasi Goreng x2, Es Teh x1".
  String _itemsLabel(List<CartItem> items) =>
      items.map((i) => '${i.produk.nama} x${i.qty}').join(', ');

  // Catatan: sengaja TIDAK menyentuh cart/produk di sini — pemanggil
  // (checkout penuh vs split bill) punya cara beda-beda buat beresin
  // cart-nya sendiri.
  Future<CheckoutResult> _queueOffline(
      String endpoint, Map<String, dynamic> body, int total, int bayar,
      {required String label}) async {
    await enqueueOfflineSale(endpoint, body, label);
    if (!isClosed) emit(state.copyWith(offlinePending: state.offlinePending + 1));
    return CheckoutResult.offlineDraft(total: total, bayar: bayar);
  }

  // Checkout transaksi biasa (bill == null) ATAU bayar open bill (bill != null).
  Future<CheckoutResult> checkout({
    required List<CartItem> items,
    required BillContext? bill,
    required int diskon,
    required JenisBayar metode,
    required int bayar,
    required String keterangan,
    required int total,
    required int idUser,
    VoucherPreview? voucher,
    int? memberId,
  }) async {
    // Bayar open bill yang sudah ada (ID-nya sudah pasti valid di server,
    // beda dari BUAT bill baru offline yang tidak diberi ID sungguhan) — jadi
    // sama amannya diantre seperti checkout tunai biasa.
    if (bill != null) {
      final body = _repo.payBillBody(
          idJenisBayar: metode.id, bayar: bayar, diskon: diskon, keterangan: keterangan, memberId: memberId);
      try {
        return await _repo.postCheckout('/open-bill/${bill.id}/pay', body);
      } catch (e) {
        if (metode.isTunai && isNetworkError(e)) {
          return _queueOffline('/open-bill/${bill.id}/pay', body, total, bayar,
              label: 'Bayar ${bill.noBill ?? 'Bill #${bill.id}'} · ${_itemsLabel(items)}');
        }
        rethrow;
      }
    }

    final body = _repo.checkoutBody(
      items: items,
      idJenisBayar: metode.id,
      idUser: idUser,
      bayar: bayar,
      diskon: diskon,
      keterangan: keterangan,
      kodeVoucher: voucher?.kode,
      memberId: memberId,
    );
    try {
      return await _repo.postCheckout('/penjualan/checkout', body);
    } catch (e) {
      // Hanya tunai (bukan QRIS) yang aman diantre offline — QRIS butuh
      // gateway online beneran, gak bisa "disimpan lalu disinkron".
      if (metode.isTunai && isNetworkError(e)) {
        return _queueOffline('/penjualan/checkout', body, total, bayar,
            label: _itemsLabel(items));
      }
      rethrow;
    }
  }

  // Bayar sebagian: mode bill -> pay-partial, transaksi biasa -> checkout
  // item terpilih. `partialItems` dipakai mode bill (id_open_bill_detail ->
  // qty), `checkoutItems` dipakai mode langsung (checkout biasa) dan buat
  // label antrean offline di kedua mode.
  Future<CheckoutResult> paySplit({
    required BillContext? bill,
    required List<Map<String, int>> partialItems,
    required List<CartItem> checkoutItems,
    required JenisBayar metode,
    required int bayar,
    required String payerName,
    required String keterangan,
    required int total,
    required int idUser,
  }) async {
    if (bill != null) {
      try {
        return await _repo.payBillPartial(
          bill.id,
          items: partialItems,
          idJenisBayar: metode.id,
          bayar: bayar,
          payerName: payerName,
          keterangan: keterangan,
        );
      } catch (e) {
        if (metode.isTunai && isNetworkError(e)) {
          final body = _repo.payBillPartialBody(
              items: partialItems,
              idJenisBayar: metode.id,
              bayar: bayar,
              payerName: payerName,
              keterangan: keterangan);
          return _queueOffline('/open-bill/${bill.id}/pay-partial', body, total, bayar,
              label: 'Split bill $payerName · ${_itemsLabel(checkoutItems)}');
        }
        rethrow;
      }
    }

    final body = _repo.checkoutBody(
      items: checkoutItems,
      idJenisBayar: metode.id,
      idUser: idUser,
      bayar: bayar,
      keterangan: keterangan,
    );
    try {
      return await _repo.postCheckout('/penjualan/checkout', body);
    } catch (e) {
      if (metode.isTunai && isNetworkError(e)) {
        return _queueOffline('/penjualan/checkout', body, total, bayar,
            label: 'Split bill $payerName · ${_itemsLabel(checkoutItems)}');
      }
      rethrow;
    }
  }

  // Muat ulang sisa bill setelah pay-partial online (dipakai split bill saat
  // belum lunas) — dilempar ke pemanggil supaya bisa cartCubit.loadBill(...).
  Future<OpenBill> reloadBill(int id) => _repo.openBill(id);

  Future<BillSaveResult> saveBill({
    required String customer,
    required String table,
    required String note,
    required List<CartItem> items,
  }) async {
    final body = _repo.billBody(customer, table, note, items);
    try {
      await _repo.createBillRaw(body);
      return BillSaveResult.saved;
    } catch (e) {
      if (isNetworkError(e)) {
        // Bill baru belum punya ID server — cukup diantre, tapi TIDAK akan
        // muncul di daftar Open Bill sampai berhasil disinkron.
        await enqueueOfflineSale('/open-bill', body, 'Bill baru · ${_itemsLabel(items)}');
        if (!isClosed) emit(state.copyWith(offlinePending: state.offlinePending + 1));
        return BillSaveResult.offline;
      }
      rethrow;
    }
  }

  Future<OpenBill> updateBill(
          int id, String customer, String table, String note, List<CartItem> items) =>
      _repo.updateBill(id, customer, table, note, items);

  Future<void> cancelBill(int id) => _repo.cancelBill(id);

  // Coba kirim ulang antrean offline (dipanggil tiap POS dibuka/refresh —
  // padanan auto-sync saat event 'online' di web). Mengembalikan jumlah yang
  // berhasil disinkron & ditolak server supaya PosPage bisa menampilkan toast.
  Future<FlushResult> trySyncOffline() async {
    final pending = await getOfflineQueue();
    if (!isClosed) emit(state.copyWith(offlinePending: pending.length));
    if (pending.isEmpty) return FlushResult(0, 0);
    final r = await flushOfflineQueue();
    if (!isClosed) {
      emit(state.copyWith(offlinePending: state.offlinePending - r.synced - r.failed));
    }
    return r;
  }
}
