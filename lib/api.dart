import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

const baseUrl = 'https://api.zonakasir.com/api';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

// Request gagal karena tidak sampai server (offline/putus) — beda dari
// ApiException yang berarti server SUDAH merespons (mis. validasi, stok habis).
bool isNetworkError(Object e) => e is! ApiException;

// Sesi disimpan di SharedPreferences (padanan localStorage 'pos-auth' di web).
class Session {
  static String? token;
  static User? user;

  static Future<void> restore() async {
    final sp = await SharedPreferences.getInstance();
    token = sp.getString('token');
    final u = sp.getString('user');
    if (u != null) user = User.fromJson(jsonDecode(u));
  }

  static Future<void> save(String t, Map<String, dynamic> u) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', t);
    await sp.setString('user', jsonEncode(u));
    token = t;
    user = User.fromJson(u);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('user');
    token = null;
    user = null;
  }

  static bool get isPro => user?.isPro ?? false;
}

Map<String, String> _headers() => {
      'Content-Type': 'application/json',
      if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
    };

// Backend selalu balas { success, message, data, meta }. Ambil `data`,
// dan ubah error jadi pesan siap tampil (padanan getErrorMessage di web).
dynamic _unwrap(http.Response res) {
  Map<String, dynamic> body = {};
  try {
    body = jsonDecode(res.body) as Map<String, dynamic>;
  } catch (_) {}
  if (res.statusCode >= 400) {
    final details = body['details'];
    final msg = '${body['message'] ?? 'Terjadi kesalahan tak terduga'}';
    throw ApiException(
      details is List && details.isNotEmpty ? '$msg: ${details.join(', ')}' : msg,
      res.statusCode,
    );
  }
  return body['data'];
}

Future<dynamic> apiGet(String path, [Map<String, dynamic>? query]) async {
  final q = (query ?? {})..removeWhere((_, v) => v == null);
  final uri = Uri.parse('$baseUrl$path')
      .replace(queryParameters: q.map((k, v) => MapEntry(k, '$v')));
  return _unwrap(await http.get(uri, headers: _headers()));
}

Future<dynamic> apiPost(String path, [Map<String, dynamic>? body]) async =>
    _unwrap(await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers(), body: jsonEncode(body ?? {})));

Future<dynamic> apiPut(String path, Map<String, dynamic> body) async =>
    _unwrap(await http.put(Uri.parse('$baseUrl$path'),
        headers: _headers(), body: jsonEncode(body)));

Future<dynamic> apiDelete(String path) async =>
    _unwrap(await http.delete(Uri.parse('$baseUrl$path'), headers: _headers()));

// Tanpa contentType eksplisit, MultipartFile.fromPath default ke
// application/octet-stream — ditolak backend (whitelist jpg/png/webp di
// middlewares/upload.js) walau isi filenya gambar valid. Tebak dari
// ekstensi supaya backend terima.
MediaType _imageContentType(String filePath) {
  final ext = filePath.toLowerCase().split('.').last;
  return switch (ext) {
    'png' => MediaType('image', 'png'),
    'webp' => MediaType('image', 'webp'),
    _ => MediaType('image', 'jpeg'),
  };
}

// Multipart POST/PUT — dipakai form produk yang boleh sertakan foto. Field
// bernilai null dilewati (server anggap "tidak diubah" saat update).
Future<dynamic> _apiMultipart(
    String method, String path, Map<String, dynamic> fields, String? filePath, String fileField) async {
  final req = http.MultipartRequest(method, Uri.parse('$baseUrl$path'));
  req.headers.addAll(_headers()..remove('Content-Type'));
  fields.forEach((k, v) {
    if (v != null) req.fields[k] = '$v';
  });
  if (filePath != null) {
    req.files.add(await http.MultipartFile.fromPath(fileField, filePath,
        contentType: _imageContentType(filePath)));
  }
  final streamed = await req.send();
  return _unwrap(await http.Response.fromStream(streamed));
}

Future<dynamic> apiPostMultipart(String path, Map<String, dynamic> fields,
        {String? filePath, String fileField = 'foto'}) =>
    _apiMultipart('POST', path, fields, filePath, fileField);

Future<dynamic> apiPutMultipart(String path, Map<String, dynamic> fields,
        {String? filePath, String fileField = 'foto'}) =>
    _apiMultipart('PUT', path, fields, filePath, fileField);

List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
    ((data as List?) ?? []).map((e) => f(e as Map<String, dynamic>)).toList();

// Beberapa endpoint hanya tersedia di plan tertentu / belum diatur merchant.
// Kegagalannya tidak boleh menjatuhkan halaman POS.
Future<T?> _opsional<T>(Future<T> Function() f) async {
  try {
    return await f();
  } catch (_) {
    return null;
  }
}

class Api {
  // ===== Auth =====
  static Future<Map<String, dynamic>> login(String u, String p) async =>
      await apiPost('/auth/login', {'username': u, 'password': p})
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> forgotPassword(String email) async =>
      await apiPost('/auth/forgot-password', {'email': email})
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> resendResetOtp(String email) async =>
      await apiPost('/auth/forgot-password/resend', {'email': email})
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> resetPassword(
          String email, String otp, String newPassword) async =>
      await apiPost('/auth/reset-password', {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }) as Map<String, dynamic>;

  // ===== Produk & referensi =====
  static Future<List<Produk>> produk(
          {String? search, dynamic categoryId, int page = 1}) async =>
      _list(
          await apiGet('/produk', {
            'search': (search ?? '').isEmpty ? null : search,
            'category_id': categoryId ?? 'all',
            'page': page,
            'limit': 30,
          }),
          Produk.fromJson);

  static Future<Produk> byBarcode(String code) async =>
      Produk.fromJson(await apiGet('/produk/barcode/$code'));

  static Future<List<Kategori>> kategori() async =>
      _list(await apiGet('/kategori'), Kategori.fromJson);

  static Future<List<JenisBayar>> jenisBayar() async =>
      _list(await apiGet('/jenis-bayar'), JenisBayar.fromJson);

  static Future<TaxSetting?> tax() async => _opsional(() async {
        final d = await apiGet('/tax');
        return TaxSetting.fromJson(d);
      });

  static Future<Qris?> qris() async => _opsional(() async {
        final d = await apiGet('/qris');
        return Qris.fromJson(d);
      });

  // ===== Varian / modifier =====
  static Future<List<ModifierGroup>> modifierFor(int produkId) async =>
      _list(await apiGet('/modifier/produk/$produkId'), ModifierGroup.fromJson);

  // ===== Member (PRO) =====
  static Future<List<Member>> member({String? search}) async => _list(
      await apiGet('/member', {
        'search': (search ?? '').isEmpty ? null : search,
        'status': 1,
        'limit': 25,
      }),
      Member.fromJson);

  // ===== Voucher =====
  static Future<VoucherPreview> validateVoucher(String kode, int subtotal) async =>
      VoucherPreview.fromJson(
          await apiGet('/voucher/validate', {'kode': kode, 'subtotal': subtotal}));

  // ===== Sesi kasir (shift) =====
  // null = sesi belum dibuka -> transaksi diblokir, sama seperti web.
  static Future<bool> shiftActive() async {
    try {
      return await apiGet('/kas-shift/active') != null;
    } catch (_) {
      return true; // gagal cek jangan sampai menghalangi kasir
    }
  }

  static Future<Map<String, dynamic>> openShift(int modalAwal,
          {String? catatan}) async =>
      await apiPost('/kas-shift', {
        'modal_awal': modalAwal,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      }) as Map<String, dynamic>;

  static Future<Map<String, dynamic>?> activeShift() async =>
      await apiGet('/kas-shift/active') as Map<String, dynamic>?;

  static Future<void> shiftMutasi(int id, String tipe, int nominal,
          {String? keterangan}) async =>
      await apiPost('/kas-shift/$id/mutasi', {
        'tipe': tipe,
        'nominal': nominal,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      });

  static Future<Map<String, dynamic>> shiftClosePreview(int id) async =>
      await apiGet('/kas-shift/$id/close-preview') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> shiftClose(int id, int actualCash,
          {String? catatan}) async =>
      await apiPost('/kas-shift/$id/close', {
        'actual_cash': actualCash,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      }) as Map<String, dynamic>;

  // ===== Open bill =====
  static Future<List<OpenBill>> openBills(
          {String status = 'OPEN', String? search}) async =>
      _list(
          await apiGet('/open-bill', {
            'status': status,
            'search': (search ?? '').isEmpty ? null : search,
            'limit': 25,
          }),
          OpenBill.fromJson);

  static Future<OpenBill> openBill(int id) async =>
      OpenBill.fromJson(await apiGet('/open-bill/$id'));

  // Publik (bukan _billBody) supaya bisa dipakai ulang buat antrean offline.
  static Map<String, dynamic> billBody(
          String customer, String table, String note, List<CartItem> items) =>
      {
        'customer_name': customer,
        'table_no': table,
        'note': note,
        'items': [
          for (final i in items) {'id_produk': i.produk.id, 'qty': i.qty}
        ],
      };

  static Future<OpenBill> createBill(
          String customer, String table, String note, List<CartItem> items) async =>
      OpenBill.fromJson(
          await apiPost('/open-bill', billBody(customer, table, note, items)));

  static Future<OpenBill> updateBill(int id, String customer, String table,
          String note, List<CartItem> items) async =>
      OpenBill.fromJson(await apiPut(
          '/open-bill/$id', billBody(customer, table, note, items)));

  static Future<void> cancelBill(int id) async =>
      await apiPost('/open-bill/$id/cancel');

  static Future<CheckoutResult> payBill(int id,
          {required int idJenisBayar,
          required int bayar,
          int diskon = 0,
          String? keterangan}) async =>
      CheckoutResult.fromJson(await apiPost('/open-bill/$id/pay', {
        'id_jenis_bayar': idJenisBayar,
        'bayar': bayar,
        'diskon': diskon,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      }));

  static Future<CheckoutResult> payBillPartial(int id,
          {required List<Map<String, int>> items,
          required int idJenisBayar,
          required int bayar,
          String? payerName,
          String? keterangan}) async =>
      CheckoutResult.fromJson(await apiPost('/open-bill/$id/pay-partial', {
        'items': items,
        'id_jenis_bayar': idJenisBayar,
        'bayar': bayar,
        if (payerName != null) 'payer_name': payerName,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      }));

  // ===== Penjualan =====
  // Body checkout mentah — dipisah dari checkout() supaya bisa disimpan apa
  // adanya di antrean offline lalu dikirim ulang lewat endpoint yang sama.
  static Map<String, dynamic> checkoutBody({
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

  static Future<CheckoutResult> checkout({
    required List<CartItem> items,
    required int idJenisBayar,
    required int idUser,
    required int bayar,
    int diskon = 0,
    String? keterangan,
    String? kodeVoucher,
    int? memberId,
  }) async =>
      CheckoutResult.fromJson(await apiPost(
          '/penjualan/checkout',
          checkoutBody(
            items: items,
            idJenisBayar: idJenisBayar,
            idUser: idUser,
            bayar: bayar,
            diskon: diskon,
            keterangan: keterangan,
            kodeVoucher: kodeVoucher,
            memberId: memberId,
          )));

  static Future<List<Penjualan>> riwayat(
          {required String dari, required String sampai, int page = 1}) async =>
      _list(
          await apiGet('/penjualan', {
            'tanggal_awal': dari,
            'tanggal_akhir': sampai,
            'status': 1,
            'page': page,
            'limit': 25,
          }),
          Penjualan.fromJson);

  static Future<Penjualan> penjualanDetail(int id) async =>
      Penjualan.fromJson(await apiGet('/penjualan/$id'));

  static Future<bool> kirimWA(int id, String nomor) async {
    final d = await apiPost('/penjualan/$id/kirim-wa', {'nomor': nomor})
        as Map<String, dynamic>;
    return d['terkirim'] == true;
  }

  // Rekap kasir hari ini untuk dashboard (padanan laporanService.penjualanPage).
  static Future<Map<String, dynamic>> rekapHariIni(int idUser, String hari) async {
    final d = await apiGet('/laporan/penjualan', {
      'tanggal_awal': hari,
      'tanggal_akhir': hari,
      'id_user': idUser,
      'status': 1,
      'page': 1,
      'limit': 8,
    });
    return (d as Map<String, dynamic>?) ?? {};
  }

  // ===== Dashboard admin (padanan dashboardService di web) =====
  static Future<DashboardSummary> dashboardSummary() async =>
      DashboardSummary.fromJson(await apiGet('/dashboard/summary') as Map<String, dynamic>);

  static Future<List<ChartBulan>> dashboardChart(int tahun) async {
    final r = await apiGet('/dashboard/chart', {'tahun': tahun}) as Map<String, dynamic>;
    return ((r['data'] as List?) ?? [])
        .map((e) => ChartBulan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===== Admin: Master Data (padanan services/*.service.ts di web) =====

  // -- Kategori (Api.kategori() sudah ada di atas, dipakai juga oleh POS) --
  static Future<Kategori> createKategori(String deskripsi) async =>
      Kategori.fromJson(await apiPost('/kategori', {'deskripsi': deskripsi}));
  static Future<Kategori> updateKategori(int id, String deskripsi) async =>
      Kategori.fromJson(await apiPut('/kategori/$id', {'deskripsi': deskripsi}));
  static Future<void> deleteKategori(int id) async => apiDelete('/kategori/$id');

  // -- Satuan --
  static Future<List<Satuan>> satuan() async => _list(await apiGet('/satuan'), Satuan.fromJson);
  static Future<Satuan> createSatuan(String nama) async =>
      Satuan.fromJson(await apiPost('/satuan', {'nama': nama}));
  static Future<Satuan> updateSatuan(int id, String nama) async =>
      Satuan.fromJson(await apiPut('/satuan/$id', {'nama': nama}));
  static Future<void> deleteSatuan(int id) async => apiDelete('/satuan/$id');

  // -- Varian / modifier groups --
  static Future<List<ModifierGroup>> modifierGroups() async =>
      _list(await apiGet('/modifier/groups'), ModifierGroup.fromJson);
  static Future<ModifierGroup> createModifierGroup(String nama, String tipe, bool wajib) async =>
      ModifierGroup.fromJson(
          await apiPost('/modifier/groups', {'nama': nama, 'tipe': tipe, 'wajib': wajib}));
  static Future<ModifierGroup> updateModifierGroup(
          int id, String nama, String tipe, bool wajib) async =>
      ModifierGroup.fromJson(await apiPut(
          '/modifier/groups/$id', {'nama': nama, 'tipe': tipe, 'wajib': wajib}));
  static Future<void> deleteModifierGroup(int id) async => apiDelete('/modifier/groups/$id');
  static Future<void> addModifierOption(int groupId, String nama, int harga) async =>
      apiPost('/modifier/groups/$groupId/options', {'nama': nama, 'harga': harga});
  static Future<void> deleteModifierOption(int id) async => apiDelete('/modifier/options/$id');
  static Future<void> setProductModifierGroups(int produkId, List<int> groupIds) async =>
      apiPut('/modifier/produk/$produkId', {'group_ids': groupIds});

  // -- Produk (Api.produk()/byBarcode() sudah ada di atas) --
  static Future<Produk> produkDetail(int id) async => Produk.fromJson(await apiGet('/produk/$id'));
  static Future<Produk> createProduk({
    required String nama,
    required int idKategori,
    required int hargaBeli,
    required int hargaJual,
    int stok = 0,
    String? barcode,
    int? idSatuan,
    String? fotoPath,
  }) async =>
      Produk.fromJson(await apiPostMultipart('/produk', {
        'nama': nama,
        'id_kategori': idKategori,
        'harga_beli': hargaBeli,
        'harga_jual': hargaJual,
        'stok': stok,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        if (idSatuan != null) 'id_satuan': idSatuan,
      }, filePath: fotoPath));
  static Future<Produk> updateProduk(int id, {
    required String nama,
    required int idKategori,
    required int hargaBeli,
    required int hargaJual,
    String? barcode,
    int? idSatuan,
    String? fotoPath,
  }) async =>
      Produk.fromJson(await apiPutMultipart('/produk/$id', {
        'nama': nama,
        'id_kategori': idKategori,
        'harga_beli': hargaBeli,
        'harga_jual': hargaJual,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        'id_satuan': idSatuan,
      }, filePath: fotoPath));
  static Future<void> deleteProduk(int id) async => apiDelete('/produk/$id');

  // -- Supplier --
  static Future<List<Supplier>> suppliers({String? search}) async => _list(
      await apiGet('/supplier', {'search': (search ?? '').isEmpty ? null : search, 'limit': 100}),
      Supplier.fromJson);
  static Future<Supplier> createSupplier(Map<String, dynamic> data) async =>
      Supplier.fromJson(await apiPost('/supplier', data));
  static Future<Supplier> updateSupplier(int id, Map<String, dynamic> data) async =>
      Supplier.fromJson(await apiPut('/supplier/$id', data));
  static Future<void> deleteSupplier(int id) async => apiDelete('/supplier/$id');

  // -- Member admin (Api.member() di atas untuk picker kasir, ini versi
  // penuh dengan status/email/alamat buat CRUD admin) --
  static Future<List<Member>> membersAdmin({String? search, int? status}) async => _list(
      await apiGet('/member', {
        'search': (search ?? '').isEmpty ? null : search,
        'status': status,
        'limit': 100,
      }),
      Member.fromJson);
  static Future<Member> createMember(Map<String, dynamic> data) async =>
      Member.fromJson(await apiPost('/member', data));
  static Future<Member> updateMember(int id, Map<String, dynamic> data) async =>
      Member.fromJson(await apiPut('/member/$id', data));
  static Future<void> deleteMember(int id) async => apiDelete('/member/$id');

  // -- Pengguna (staff kasir/gudang) --
  static Future<List<Pengguna>> pengguna() async =>
      _list(await apiGet('/pengguna'), Pengguna.fromJson);
  static Future<Pengguna> createPengguna(Map<String, dynamic> data) async =>
      Pengguna.fromJson(await apiPost('/pengguna', data));
  static Future<Pengguna> updatePengguna(int id, Map<String, dynamic> data) async =>
      Pengguna.fromJson(await apiPut('/pengguna/$id', data));
  static Future<void> deletePengguna(int id) async => apiDelete('/pengguna/$id');
  static Future<Map<String, dynamic>> resetPenggunaPassword(int id) async =>
      await apiPost('/pengguna/$id/reset-password') as Map<String, dynamic>;

  // -- Voucher (VoucherPreview/validateVoucher di atas dipakai kasir saat checkout) --
  static Future<List<Voucher>> vouchers() async =>
      _list(await apiGet('/voucher'), Voucher.fromJson);
  static Future<Voucher> createVoucher(Map<String, dynamic> data) async =>
      Voucher.fromJson(await apiPost('/voucher', data));
  static Future<Voucher> updateVoucher(int id, Map<String, dynamic> data) async =>
      Voucher.fromJson(await apiPut('/voucher/$id', data));
  static Future<void> deleteVoucher(int id) async => apiDelete('/voucher/$id');

  // ===== Admin: Operasional (padanan services/*.service.ts di web) =====

  // -- Stok opname (penyesuaian stok) --
  static Future<void> adjustStock(int idProduk, int jenis, int qty, {String? keterangan}) async =>
      apiPost('/produk/$idProduk/stok', {
        'jenis': jenis, // 1 = tambah (masuk), 2 = kurangi (keluar)
        'qty': qty,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
      });

  // -- Pembelian barang --
  static Future<List<Pembelian>> pembelian({String? search, int? status}) async => _list(
      await apiGet('/pembelian', {
        'search': (search ?? '').isEmpty ? null : search,
        'status': status,
        'limit': 25,
      }),
      Pembelian.fromJson);
  static Future<Pembelian> pembelianDetail(int id) async =>
      Pembelian.fromJson(await apiGet('/pembelian/$id'));
  static Future<int> createPembelian(Map<String, dynamic> data) async {
    final d = await apiPost('/pembelian', data) as Map<String, dynamic>;
    return (d['id'] as num?)?.toInt() ?? 0;
  }
  static Future<void> updatePembelian(int id, Map<String, dynamic> data) async =>
      apiPut('/pembelian/$id', data);
  static Future<void> deletePembelian(int id) async => apiDelete('/pembelian/$id');
  static Future<void> selesaikanPembelian(int id) async => apiPost('/pembelian/$id/selesaikan');

  // -- Retur barang --
  static Future<List<Retur>> retur({String? search, int? status}) async => _list(
      await apiGet('/retur', {
        'search': (search ?? '').isEmpty ? null : search,
        'status': status,
        'limit': 25,
      }),
      Retur.fromJson);
  static Future<Retur> returDetail(int id) async => Retur.fromJson(await apiGet('/retur/$id'));
  static Future<int> createRetur(Map<String, dynamic> data) async {
    final d = await apiPost('/retur', data) as Map<String, dynamic>;
    return (d['id'] as num?)?.toInt() ?? 0;
  }
  static Future<void> updateRetur(int id, Map<String, dynamic> data) async =>
      apiPut('/retur/$id', data);
  static Future<void> deleteRetur(int id) async => apiDelete('/retur/$id');
  static Future<void> selesaikanRetur(int id) async => apiPost('/retur/$id/selesaikan');
  static Future<void> batalRetur(int id) async => apiPost('/retur/$id/batal');

  // -- Katalog (slug link + banner) --
  static Future<Map<String, dynamic>> merchantMe() async =>
      await apiGet('/merchant/me') as Map<String, dynamic>;
  static Future<Map<String, dynamic>> updateMerchantSlug(String slug) async =>
      await apiPut('/merchant/me', {'slug': slug}) as Map<String, dynamic>;
  static Future<Map<String, dynamic>> identitas() async =>
      await apiGet('/identitas') as Map<String, dynamic>;
  static Future<Map<String, dynamic>> uploadIdentitasBanner(String filePath) async =>
      await apiPostMultipart('/identitas/banner', {}, filePath: filePath, fileField: 'banner')
          as Map<String, dynamic>;
  static Future<Map<String, dynamic>> uploadIdentitasLogo(String filePath) async =>
      await apiPostMultipart('/identitas/logo', {}, filePath: filePath, fileField: 'logo')
          as Map<String, dynamic>;

  // -- Pengaturan: identitas toko, pajak, QRIS (admin) --
  static Future<Map<String, dynamic>> updateIdentitas(
          {String? nama, String? alamat, String? noTelp, String? email, String? website}) async =>
      await apiPut('/identitas', {
        'nama': nama,
        'alamat': alamat,
        'no_telp': noTelp,
        'email': email,
        'website': website,
      }) as Map<String, dynamic>;

  static Future<TaxSetting> updateTax(
          {required bool ppnEnabled,
          required num ppnPersen,
          required bool serviceEnabled,
          required num servicePersen}) async =>
      TaxSetting.fromJson(await apiPut('/tax', {
        'ppn_enabled': ppnEnabled,
        'ppn_persen': ppnPersen,
        'service_enabled': serviceEnabled,
        'service_persen': servicePersen,
      }));

  static Future<Qris> updateQris(
          {required String merchantName, required String nmid, required bool isActive, String? filePath}) async =>
      Qris.fromJson(await apiPutMultipart('/qris', {
        'merchant_name': merchantName,
        'nmid': nmid,
        'is_active': isActive,
      }, filePath: filePath, fileField: 'image'));

  // -- Laporan (admin) --
  // Daftar transaksi seluruh kasir (beda dari riwayat() yang scope-nya
  // transaksi kasir sendiri saja) — dipakai halaman Laporan Transaksi admin.
  static Future<List<Penjualan>> penjualanList(
          {required String dari, required String sampai, int status = 1, int page = 1}) async =>
      _list(
          await apiGet('/penjualan', {
            'tanggal_awal': dari,
            'tanggal_akhir': sampai,
            'status': status,
            'page': page,
            'limit': 25,
          }),
          Penjualan.fromJson);

  static Future<void> voidPenjualan(int id) async => apiPost('/penjualan/$id/void');

  static Future<LaporanPenjualan> laporanPenjualan(String dari, String sampai) async =>
      LaporanPenjualan.fromJson(await apiGet('/laporan/penjualan', {
        'tanggal_awal': dari,
        'tanggal_akhir': sampai,
        'id_user': 'all',
        'status': 1,
      }) as Map<String, dynamic>);

  static Future<LaporanPendapatan> laporanPendapatan(String dari, String sampai) async =>
      LaporanPendapatan.fromJson(await apiGet(
          '/laporan/pendapatan', {'tanggal_awal': dari, 'tanggal_akhir': sampai, 'status': 1}) as Map<String, dynamic>);

  // Rekap lengkap cuma untuk plan PRO/BUSINESS — backend balas 403 di FREE,
  // jadi dibungkus opsional sama seperti tax()/qris().
  static Future<RekapLaporan?> laporanRekap(String dari, String sampai) async => _opsional(() async {
        final d = await apiGet('/laporan/rekap',
            {'tanggal_awal': dari, 'tanggal_akhir': sampai, 'status': 1, 'top_limit': 20});
        return RekapLaporan.fromJson(d as Map<String, dynamic>);
      });

  // -- Laporan closing kasir (admin) --
  static Future<DailyReport> closingReportDaily(String tanggal) async =>
      DailyReport.fromJson(await apiGet('/kas-shift/report/daily', {'tanggal': tanggal})
          as Map<String, dynamic>);

  // -- Langganan / billing (admin) --
  static Future<Billing> subscriptionBilling() async =>
      Billing.fromJson(await apiGet('/subscription/billing') as Map<String, dynamic>);

  static Future<SubscriptionSetting> subscriptionSetting() async =>
      SubscriptionSetting.fromJson(await apiGet('/subscription/setting') as Map<String, dynamic>);

  // Midtrans Snap — buat tagihan, balik SNAP_REDIRECT_URL buat dimuat di
  // WebView in-app (padanan createPayment di subscriptionService.js backend).
  static Future<SubscriptionPayment> createSubscriptionPayment(
          String plan, String paket) async =>
      SubscriptionPayment.fromJson(await apiPost(
          '/subscription/payment', {'plan': plan, 'paket': paket}) as Map<String, dynamic>);

  // Backend query ulang status ke Midtrans kalau belum final — aman dipoll.
  static Future<SubscriptionPayment> subscriptionPaymentStatus(int id) async =>
      SubscriptionPayment.fromJson(
          await apiGet('/subscription/payment/$id/status') as Map<String, dynamic>);

  static Future<void> cancelSubscriptionPayment(int id) async =>
      await apiPost('/subscription/payment/$id/cancel');
}
