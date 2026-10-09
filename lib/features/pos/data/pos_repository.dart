import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../models/cart_item.dart';

// Wraps the raw HTTP calls the POS screen + its sheets need — a 1:1 port of
// the relevant `Api.xxx` static methods from the old lib/api.dart, using
// apiGet/apiPost/apiPut/apiDelete/apiList/apiOpsional from
// core/network/api_client.dart directly (no dependency on the old Api class).
class PosRepository {
  // ===== Produk & referensi =====
  Future<List<Produk>> produk(
          {String? search, dynamic categoryId, int page = 1}) async =>
      apiList(
          await apiGet('/produk', {
            'search': (search ?? '').isEmpty ? null : search,
            'category_id': categoryId ?? 'all',
            'page': page,
            'limit': 30,
          }),
          Produk.fromJson);

  Future<Produk> byBarcode(String code) async =>
      Produk.fromJson(await apiGet('/produk/barcode/$code'));

  Future<List<Kategori>> kategori() async =>
      apiList(await apiGet('/kategori'), Kategori.fromJson);

  Future<List<JenisBayar>> jenisBayar() async =>
      apiList(await apiGet('/jenis-bayar'), JenisBayar.fromJson);

  Future<TaxSetting?> tax() async => apiOpsional(() async {
        final d = await apiGet('/tax');
        return TaxSetting.fromJson(d);
      });

  Future<Qris?> qris() async => apiOpsional(() async {
        final d = await apiGet('/qris');
        return Qris.fromJson(d);
      });

  // ===== Varian / modifier =====
  Future<List<ModifierGroup>> modifierFor(int produkId) async =>
      apiList(await apiGet('/modifier/produk/$produkId'), ModifierGroup.fromJson);

  // ===== Member (PRO) =====
  Future<List<Member>> member({String? search}) async => apiList(
      await apiGet('/member', {
        'search': (search ?? '').isEmpty ? null : search,
        'status': 1,
        'limit': 25,
      }),
      Member.fromJson);

  // ===== Voucher =====
  Future<VoucherPreview> validateVoucher(String kode, int subtotal) async =>
      VoucherPreview.fromJson(
          await apiGet('/voucher/validate', {'kode': kode, 'subtotal': subtotal}));

  // ===== Sesi kasir (shift) =====
  // false-safe di error -> gagal cek jangan sampai menghalangi kasir.
  Future<bool> shiftActive() async {
    try {
      return await apiGet('/kas-shift/active') != null;
    } catch (_) {
      return true;
    }
  }

  Future<Map<String, dynamic>> openShift(int modalAwal, {String? catatan}) async =>
      await apiPost('/kas-shift', {
        'modal_awal': modalAwal,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      }) as Map<String, dynamic>;

  // ===== Open bill =====
  Future<List<OpenBill>> openBills({String status = 'OPEN', String? search}) async =>
      apiList(
          await apiGet('/open-bill', {
            'status': status,
            'search': (search ?? '').isEmpty ? null : search,
            'limit': 25,
          }),
          OpenBill.fromJson);

  Future<OpenBill> openBill(int id) async => OpenBill.fromJson(await apiGet('/open-bill/$id'));

  // Publik supaya bisa dipakai ulang buat antrean offline (lihat
  // CheckoutCubit.saveBill).
  Map<String, dynamic> billBody(
          String customer, String table, String note, List<CartItem> items) =>
      {
        'customer_name': customer,
        'table_no': table,
        'note': note,
        'items': [
          for (final i in items) {'id_produk': i.produk.id, 'qty': i.qty}
        ],
      };

  // Hasil create-nya tidak dipakai pemanggil (simpan bill lama juga begitu),
  // cukup lempar error kalau gagal.
  Future<void> createBillRaw(Map<String, dynamic> body) async =>
      await apiPost('/open-bill', body);

  Future<OpenBill> updateBill(int id, String customer, String table, String note,
          List<CartItem> items) async =>
      OpenBill.fromJson(await apiPut('/open-bill/$id', billBody(customer, table, note, items)));

  Future<void> cancelBill(int id) async => await apiPost('/open-bill/$id/cancel');

  Map<String, dynamic> payBillBody(
          {required int idJenisBayar, required int bayar, int diskon = 0, String? keterangan, int? memberId}) =>
      {
        'id_jenis_bayar': idJenisBayar,
        'bayar': bayar,
        'diskon': diskon,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
        // Nama field sama dengan checkout biasa; belum dipastikan backend
        // /open-bill/:id/pay memakainya (field tak dikenal tidak ditolak).
        if (memberId != null) 'member_id': memberId,
      };

  Future<CheckoutResult> payBill(int id,
          {required int idJenisBayar, required int bayar, int diskon = 0, String? keterangan}) async =>
      CheckoutResult.fromJson(await apiPost('/open-bill/$id/pay',
          payBillBody(idJenisBayar: idJenisBayar, bayar: bayar, diskon: diskon, keterangan: keterangan)));

  Map<String, dynamic> payBillPartialBody({
    required List<Map<String, int>> items,
    required int idJenisBayar,
    required int bayar,
    String? payerName,
    String? keterangan,
  }) =>
      {
        'items': items,
        'id_jenis_bayar': idJenisBayar,
        'bayar': bayar,
        if (payerName != null && payerName.isNotEmpty) 'payer_name': payerName,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      };

  Future<CheckoutResult> payBillPartial(int id, {
    required List<Map<String, int>> items,
    required int idJenisBayar,
    required int bayar,
    String? payerName,
    String? keterangan,
  }) async =>
      CheckoutResult.fromJson(await apiPost('/open-bill/$id/pay-partial',
          payBillPartialBody(
              items: items,
              idJenisBayar: idJenisBayar,
              bayar: bayar,
              payerName: payerName,
              keterangan: keterangan)));

  // ===== Penjualan =====
  // Body checkout mentah — dipisah dari checkout() supaya bisa disimpan apa
  // adanya di antrean offline lalu dikirim ulang lewat endpoint yang sama.
  Map<String, dynamic> checkoutBody({
    required List<CartItem> items,
    required int idJenisBayar,
    required int idUser,
    required int bayar,
    int diskon = 0,
    String? keterangan,
    String? kodeVoucher,
    int? memberId,
  }) =>
      {
        'items': [
          for (final i in items)
            {
              'id_produk': i.produk.id,
              'qty': i.qty,
              'modifier_option_ids': i.modifierIds,
            }
        ],
        'id_jenis_bayar': idJenisBayar,
        'id_user': idUser,
        'bayar': bayar,
        'diskon': diskon,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
        if (kodeVoucher != null) 'kode_voucher': kodeVoucher,
        if (memberId != null) 'member_id': memberId,
      };

  // Post generik hasil-CheckoutResult — dipakai checkout biasa, pay bill, dan
  // pay-partial split bill (semua balas bentuk penjualan yang sama).
  Future<CheckoutResult> postCheckout(String endpoint, Map<String, dynamic> body) async =>
      CheckoutResult.fromJson(await apiPost(endpoint, body));

  // ===== Kirim struk WA (dipakai SuccessSheet) =====
  Future<bool> kirimWA(int id, String nomor) async {
    final d = await apiPost('/penjualan/$id/kirim-wa', {'nomor': nomor}) as Map<String, dynamic>;
    return d['terkirim'] == true;
  }
}
