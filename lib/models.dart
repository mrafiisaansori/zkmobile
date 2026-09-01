int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class User {
  final int id;
  final String nama, username, role, plan;
  User.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        nama = '${j['nama'] ?? ''}',
        username = '${j['username'] ?? ''}',
        role = '${j['role'] ?? ''}',
        plan = '${(j['merchant'] ?? const {})['plan'] ?? 'FREE'}';

  // Member, open bill, split bill, dan pajak hanya untuk plan berbayar.
  bool get isPro => plan == 'PRO' || plan == 'BUSINESS';
}

class Produk {
  final int id, stok, hargaJual;
  final String nama;
  final String? foto, satuan;
  // Dipakai halaman admin (form edit produk) — kasir tidak butuh ini.
  final int idKategori, hargaBeli;
  final int? idSatuan;
  final String? barcode;
  Produk.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        stok = _i(j['STOK']),
        hargaJual = _i(j['HARGA_JUAL']),
        satuan = _s(j['satuan']?['NAMA']),
        // Urutan kandidat sama dengan utils/image.ts di web.
        foto = _s(j['FOTO_URL']) ??
            _s(j['FOTO']) ??
            _s(j['image_url']) ??
            _s(j['foto_url']),
        idKategori = _i(j['ID_KATEGORI']),
        hargaBeli = _i(j['HARGA_BELI']),
        idSatuan = j['ID_SATUAN'] == null ? null : _i(j['ID_SATUAN']),
        barcode = _s(j['BARCODE']);

  // Produk sintetis untuk item open bill (detail bill tidak membawa data produk penuh).
  Produk.raw(this.id, this.nama, this.hargaJual, this.stok,
      {this.foto, this.satuan, this.idKategori = 0, this.hargaBeli = 0, this.idSatuan, this.barcode});
}

class Kategori {
  final int id;
  final String deskripsi;
  Kategori.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        deskripsi = '${j['DESKRIPSI'] ?? ''}';
}

class JenisBayar {
  final int id;
  final String nama;
  JenisBayar.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}';
  bool get isQris => nama.toUpperCase().contains('QRIS');
  bool get isTransfer => nama.toUpperCase().contains('TRANSFER');
  bool get isTunai => !isQris && !isTransfer;
}

class Qris {
  final String? merchantName, nmid, imageUrl;
  final bool isActive;
  Qris.fromJson(Map<String, dynamic> j)
      : merchantName = _s(j['MERCHANT_NAME']),
        nmid = _s(j['NMID']),
        imageUrl = _s(j['IMAGE_URL']),
        isActive = j['IS_ACTIVE'] == true;
  bool get siap => isActive && imageUrl != null;
}

class TaxSetting {
  final bool ppnOn, serviceOn;
  final num ppnPersen, servicePersen;
  TaxSetting.fromJson(Map<String, dynamic> j)
      : ppnOn = j['PPN_ENABLED'] == true,
        serviceOn = j['SERVICE_ENABLED'] == true,
        ppnPersen = j['PPN_PERSEN'] ?? 0,
        servicePersen = j['SERVICE_PERSEN'] ?? 0;
}

class VoucherPreview {
  final String kode;
  final int diskon;
  VoucherPreview.fromJson(Map<String, dynamic> j)
      : kode = '${j['kode'] ?? ''}',
        diskon = _i(j['diskon']);
}

class Member {
  final int id;
  final String nama, noHp;
  final String? kode;
  // Field tambahan dipakai halaman admin (Master Member) — kasir cuma pakai
  // id/nama/noHp/kode buat member-picker, sisanya opsional/nullable.
  final String? email, alamat, tanggalDaftar;
  final int status;
  Member.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        noHp = '${j['NO_HP'] ?? ''}',
        kode = _s(j['KODE_MEMBER']),
        email = _s(j['EMAIL']),
        alamat = _s(j['ALAMAT']),
        tanggalDaftar = _s(j['TANGGAL_DAFTAR']),
        status = j['STATUS'] == null ? 1 : _i(j['STATUS']);
}

class Satuan {
  final int id;
  final String nama;
  Satuan.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}';
}

class Supplier {
  final int id;
  final String nama;
  final String? alamat, noTelp, email, catatan;
  final int status;
  Supplier.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        alamat = _s(j['ALAMAT']),
        noTelp = _s(j['NO_TELP']),
        email = _s(j['EMAIL']),
        catatan = _s(j['CATATAN']),
        status = j['STATUS'] == null ? 1 : _i(j['STATUS']);
}

class Pengguna {
  final int id, level;
  final String nama, username;
  final String? telp;
  Pengguna.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        username = '${j['USERNAME'] ?? ''}',
        level = _i(j['LEVEL']),
        telp = _s(j['TELP']);

  // 1 = Admin (tidak bisa dibuat/diubah dari layar ini), 2 = Kasir, 3 = Gudang.
  String get roleLabel => level == 1 ? 'Admin' : level == 3 ? 'Gudang' : 'Kasir';
}

class Voucher {
  final int id, nilai, minTransaksi;
  final String kode, tipe;
  final String? validFrom, validUntil;
  final bool aktif;
  Voucher.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        kode = '${j['KODE'] ?? ''}',
        tipe = '${j['TIPE'] ?? 'NOMINAL'}',
        nilai = _i(j['NILAI']),
        minTransaksi = _i(j['MIN_TRANSAKSI']),
        validFrom = _s(j['VALID_FROM']),
        validUntil = _s(j['VALID_UNTIL']),
        aktif = j['IS_ACTIVE'] == true;
  bool get persen => tipe == 'PERSEN';
}

class ModifierOption {
  final int id, harga;
  final String nama;
  ModifierOption.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        harga = _i(j['HARGA']);
}

class ModifierGroup {
  final int id;
  final String nama, tipe;
  final bool wajib;
  final List<ModifierOption> options;
  ModifierGroup.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        tipe = '${j['TIPE'] ?? 'SINGLE'}',
        wajib = j['WAJIB'] == true,
        options = ((j['options'] as List?) ?? [])
            .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
            .toList();
  bool get single => tipe == 'SINGLE';
}

class OpenBillDetail {
  final int id, idProduk, hargaJual, qty, paidQty;
  final String namaProduk;
  final int stok;
  final String? modifier, modifierOptions;
  OpenBillDetail.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        idProduk = _i(j['ID_PRODUK']),
        hargaJual = _i(j['HARGA_JUAL']),
        qty = _i(j['QTY']),
        paidQty = _i(j['PAID_QTY']),
        namaProduk = _s(j['produk']?['NAMA']) ?? 'Produk ${_i(j['ID_PRODUK'])}',
        stok = _i(j['produk']?['STOK'] ?? j['QTY']),
        modifier = _s(j['MODIFIER']),
        modifierOptions = _s(j['MODIFIER_OPTIONS']);

  int get sisaQty => qty - paidQty;
}

class OpenBill {
  final int id, total;
  final String status;
  final String? noBill, customerName, tableNo, note, kasir, createdAt;
  final List<OpenBillDetail> detail;
  OpenBill.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        total = _i(j['TOTAL']),
        status = '${j['STATUS'] ?? 'OPEN'}',
        noBill = _s(j['NO_BILL']),
        customerName = _s(j['CUSTOMER_NAME']),
        tableNo = _s(j['TABLE_NO']),
        note = _s(j['NOTE']),
        kasir = _s(j['kasir']?['NAMA']),
        createdAt = _s(j['CREATED_AT']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => OpenBillDetail.fromJson(e as Map<String, dynamic>))
            .toList();
}

class DetailPenjualan {
  final int qty, hargaJual, diskon;
  final String namaProduk;
  final String? modifier, satuan;
  DetailPenjualan.fromJson(Map<String, dynamic> j)
      : qty = _i(j['QTY']),
        hargaJual = _i(j['HARGA_JUAL']),
        diskon = _i(j['DISKON']),
        namaProduk = '${j['produk']?['NAMA'] ?? '-'}',
        modifier = _s(j['MODIFIER']),
        satuan = _s(j['SATUAN']);

  int get subtotal => qty * hargaJual - diskon;
}

class Penjualan {
  final int id, total, status;
  final String? noNota, tanggal, jam, keterangan, jenisBayar, statusBayar,
      namaMember, namaKasir;
  final int noNotaUrut;
  final List<DetailPenjualan> detail;
  Penjualan.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        total = _i(j['TOTAL']),
        status = j['STATUS'] == null ? 1 : _i(j['STATUS']),
        noNota = _s(j['NO_NOTA']),
        noNotaUrut = _i(j['NO_NOTA_URUT']),
        tanggal = _s(j['TANGGAL']),
        jam = _s(j['JAM']),
        keterangan = _s(j['KETERANGAN']),
        jenisBayar = _s(j['jenisBayar']?['NAMA']),
        statusBayar = _s(j['STATUS_BAYAR']),
        namaMember = _s(j['member']?['NAMA']),
        namaKasir = _s(j['kasir']?['NAMA']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => DetailPenjualan.fromJson(e as Map<String, dynamic>))
            .toList();

  // Padanan nomorNotaPenjualanLabel di web: pakai NO_NOTA, fallback ke urut/ID.
  String get label =>
      noNota ?? (noNotaUrut > 0 ? '#$noNotaUrut' : '#$id');
}

// ===== Dashboard admin (padanan DashboardSummary di web src/types/index.ts) =====
class StokMenipisItem {
  final int id, stok;
  final String nama;
  StokMenipisItem.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        stok = _i(j['STOK']);
}

class ProdukTerlaris {
  final int idProduk, qty, omzet;
  final String nama;
  ProdukTerlaris.fromJson(Map<String, dynamic> j)
      : idProduk = _i(j['id_produk']),
        nama = '${j['nama'] ?? ''}',
        qty = _i(j['qty']),
        omzet = _i(j['omzet']);
}

class ChartBulan {
  final int bulan, omzet, laba;
  ChartBulan.fromJson(Map<String, dynamic> j)
      : bulan = _i(j['bulan']),
        omzet = _i(j['omzet']),
        laba = _i(j['laba']);
}

class DashboardSummary {
  final String tanggal;
  final int transaksiHariIni,
      pendapatanHariIni,
      labaHariIni,
      ppnHariIni,
      serviceHariIni,
      totalDibayarHariIni,
      rataRataTransaksi;
  final List<StokMenipisItem> stokMenipis;
  final List<ProdukTerlaris> produkTerlaris;
  final List<Penjualan> transaksiTerbaru;
  DashboardSummary.fromJson(Map<String, dynamic> j)
      : tanggal = '${j['tanggal'] ?? ''}',
        transaksiHariIni = _i(j['transaksi_hari_ini']),
        pendapatanHariIni = _i(j['pendapatan_hari_ini']),
        labaHariIni = _i(j['laba_hari_ini']),
        ppnHariIni = _i(j['ppn_hari_ini']),
        serviceHariIni = _i(j['service_hari_ini']),
        totalDibayarHariIni = _i(j['total_dibayar_hari_ini']),
        rataRataTransaksi = _i(j['rata_rata_transaksi']),
        stokMenipis = ((j['stok_menipis'] as List?) ?? [])
            .map((e) => StokMenipisItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        produkTerlaris = ((j['produk_terlaris'] as List?) ?? [])
            .map((e) => ProdukTerlaris.fromJson(e as Map<String, dynamic>))
            .toList(),
        transaksiTerbaru = ((j['transaksi_terbaru'] as List?) ?? [])
            .map((e) => Penjualan.fromJson(e as Map<String, dynamic>))
            .toList();
}

class CheckoutResult {
  final int id, total, bayar, kembalian, remainingTotal;
  final String noNota, billStatus;
  final bool offline;
  CheckoutResult.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        noNota = '${j['no_nota'] ?? ''}',
        total = _i(j['total']),
        bayar = _i(j['bayar']),
        kembalian = _i(j['kembalian']),
        remainingTotal = _i(j['remaining_total']),
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

// ===== Keranjang =====
int _lineSeq = 0;

// Satu baris keranjang. Baris dengan varian selalu terpisah, sama seperti web.
class CartItem {
  final String lineId;
  final Produk produk;
  final int? openBillDetailId;
  final List<ModifierOption> modifiers;
  int qty;
  int stokOverride;

  CartItem(this.produk, this.qty,
      {this.modifiers = const [], this.openBillDetailId, int? stok})
      : lineId = 'l${_lineSeq++}',
        stokOverride = stok ?? produk.stok;

  int get modifierExtra => modifiers.fold(0, (s, m) => s + m.harga);
  int get unit => produk.hargaJual + modifierExtra;
  int get total => unit * qty;
  int get stok => stokOverride;
  String? get modifierText =>
      modifiers.isEmpty ? null : modifiers.map((m) => m.nama).join(', ');
  List<int> get modifierIds => modifiers.map((m) => m.id).toList();
}

// Rincian tagihan: subtotal - diskon - voucher, lalu PPN & service (plan PRO/BUSINESS).
class Tagihan {
  final int subtotal, diskon, voucher, ppn, service;
  Tagihan(this.subtotal, this.diskon, this.voucher, this.ppn, this.service);

  factory Tagihan.hitung({
    required List<CartItem> items,
    int diskon = 0,
    int voucher = 0,
    TaxSetting? tax,
    bool isPro = false,
  }) {
    final subtotal = items.fold<int>(0, (s, i) => s + i.total);
    final potong = (diskon + voucher) > subtotal ? subtotal : (diskon + voucher);
    final dpp = subtotal - potong;
    final ppn =
        isPro && (tax?.ppnOn ?? false) ? (dpp * tax!.ppnPersen / 100).round() : 0;
    final svc = isPro && (tax?.serviceOn ?? false)
        ? (dpp * tax!.servicePersen / 100).round()
        : 0;
    return Tagihan(
        subtotal, diskon > subtotal ? subtotal : diskon, potong - (diskon > subtotal ? subtotal : diskon), ppn, svc);
  }

  int get dpp => subtotal - diskon - voucher;
  int get total => dpp + ppn + service;
  int kembalian(int bayar) => bayar - total;
}

// ===== Pembelian barang (padanan services/pembelian.service.ts) =====
class PembelianDetail {
  final int id, idProduk, hargaBeli, qty;
  final String? namaProduk;
  PembelianDetail.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        idProduk = _i(j['ID_PRODUK']),
        hargaBeli = _i(j['HARGA_BELI']),
        qty = _i(j['QTY']),
        namaProduk = _s(j['produk']?['NAMA']);
  int get subtotal => hargaBeli * qty;
}

class Pembelian {
  final int id, status;
  final String noNota;
  final String? tanggal, catatan, namaSupplier;
  final int? idSupplier;
  final List<PembelianDetail> detail;
  Pembelian.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        noNota = '${j['NO_NOTA'] ?? ''}',
        tanggal = _s(j['TANGGAL']),
        status = _i(j['STATUS']),
        catatan = _s(j['CATATAN']),
        idSupplier = j['ID_SUPPLIER'] == null ? null : _i(j['ID_SUPPLIER']),
        namaSupplier = _s(j['supplier']?['NAMA']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => PembelianDetail.fromJson(e as Map<String, dynamic>))
            .toList();
  int get total => detail.fold(0, (s, d) => s + d.subtotal);
}

// ===== Retur barang (padanan services/retur.service.ts) =====
class ReturDetail {
  final int id, idProduk, qty;
  final int? harga;
  final String? namaProduk, alasan, kondisi;
  ReturDetail.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        idProduk = _i(j['ID_PRODUK']),
        qty = _i(j['QTY']),
        harga = j['HARGA'] == null ? null : _i(j['HARGA']),
        namaProduk = _s(j['produk']?['NAMA']),
        alasan = _s(j['ALASAN']),
        kondisi = _s(j['KONDISI']);
}

class Retur {
  final int id, status;
  final String noNota;
  final String? tanggal, catatan, namaSupplier, noNotaPembelian;
  final int? idSupplier, idPembelian;
  final List<ReturDetail> detail;
  Retur.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        noNota = '${j['NO_NOTA'] ?? ''}',
        tanggal = _s(j['TANGGAL']),
        status = _i(j['STATUS']),
        catatan = _s(j['CATATAN']),
        idSupplier = j['ID_SUPPLIER'] == null ? null : _i(j['ID_SUPPLIER']),
        namaSupplier = _s(j['supplier']?['NAMA']),
        idPembelian = j['ID_PEMBELIAN'] == null ? null : _i(j['ID_PEMBELIAN']),
        noNotaPembelian = _s(j['pembelian']?['NO_NOTA']),
        detail = ((j['detail'] as List?) ?? [])
            .map((e) => ReturDetail.fromJson(e as Map<String, dynamic>))
            .toList();
}

// ===== Laporan (padanan src/types/index.ts LaporanPenjualan/LaporanPendapatan/RekapLaporan) =====
class LaporanPenjualan {
  final int jumlahTransaksi, omzet, totalPpn, totalService, totalDibayar;
  LaporanPenjualan.fromJson(Map<String, dynamic> j)
      : jumlahTransaksi = _i(j['jumlah_transaksi']),
        omzet = _i(j['omzet']),
        totalPpn = _i(j['total_ppn']),
        totalService = _i(j['total_service']),
        totalDibayar = _i(j['total_dibayar']);
}

class LaporanPendapatan {
  final int omzet, modal, laba, ppn, service, totalDibayar;
  LaporanPendapatan.fromJson(Map<String, dynamic> j)
      : omzet = _i(j['omzet']),
        modal = _i(j['modal']),
        laba = _i(j['laba']),
        ppn = _i(j['ppn']),
        service = _i(j['service']),
        totalDibayar = _i(j['total_dibayar']);
}

class RekapMetodeBayar {
  final String metode;
  final int jumlahTransaksi, total;
  RekapMetodeBayar.fromJson(Map<String, dynamic> j)
      : metode = '${j['metode'] ?? '-'}',
        jumlahTransaksi = _i(j['jumlah_transaksi']),
        total = _i(j['total']);
}

class RekapKasir {
  final String kasir;
  final int jumlahTransaksi, total;
  RekapKasir.fromJson(Map<String, dynamic> j)
      : kasir = '${j['kasir'] ?? '-'}',
        jumlahTransaksi = _i(j['jumlah_transaksi']),
        total = _i(j['total']);
}

class RekapLaporan {
  final List<RekapMetodeBayar> perMetodeBayar;
  final List<RekapKasir> perKasir;
  final List<ProdukTerlaris> produkTerlaris;
  final List<StokMenipisItem> produkStokMenipis;
  RekapLaporan.fromJson(Map<String, dynamic> j)
      : perMetodeBayar = ((j['per_metode_bayar'] as List?) ?? [])
            .map((e) => RekapMetodeBayar.fromJson(e as Map<String, dynamic>))
            .toList(),
        perKasir = ((j['per_kasir'] as List?) ?? [])
            .map((e) => RekapKasir.fromJson(e as Map<String, dynamic>))
            .toList(),
        produkTerlaris = ((j['produk_terlaris'] as List?) ?? [])
            .map((e) => ProdukTerlaris.fromJson(e as Map<String, dynamic>))
            .toList(),
        produkStokMenipis = ((j['produk_stok_menipis'] as List?) ?? [])
            .map((e) => StokMenipisItem.fromJson({
                  'ID': e['id'],
                  'NAMA': e['nama'],
                  'STOK': e['stok'],
                }))
            .toList();
}

// ===== Laporan closing kasir (padanan DailyReport/DailyReportRow) =====
class DailyReportRow {
  final int idShift;
  final String? kasir, station, bukaAt, tutupAt;
  final String status;
  final int modalAwal, cashSales, nonCashSales, totalSales, expectedCash;
  final int? actualCash, selisihCash;
  DailyReportRow.fromJson(Map<String, dynamic> j)
      : idShift = _i(j['id_shift']),
        kasir = _s(j['kasir']),
        station = _s(j['station']),
        bukaAt = _s(j['buka_at']),
        tutupAt = _s(j['tutup_at']),
        status = '${j['status'] ?? 'OPEN'}',
        modalAwal = _i(j['modal_awal']),
        cashSales = _i(j['cash_sales']),
        nonCashSales = _i(j['non_cash_sales']),
        totalSales = _i(j['total_sales']),
        expectedCash = _i(j['expected_cash']),
        actualCash = j['actual_cash'] == null ? null : _i(j['actual_cash']),
        selisihCash = j['selisih_cash'] == null ? null : _i(j['selisih_cash']);
}

class DailyReport {
  final String tanggal;
  final int jumlahShift, totalCashSales, totalNonCashSales, totalOmzet, totalSelisihCash;
  final List<DailyReportRow> shift;
  DailyReport.fromJson(Map<String, dynamic> j)
      : tanggal = '${j['tanggal'] ?? ''}',
        jumlahShift = _i(j['jumlah_shift']),
        shift = ((j['shift'] as List?) ?? [])
            .map((e) => DailyReportRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCashSales = _i(j['ringkasan']?['total_cash_sales']),
        totalNonCashSales = _i(j['ringkasan']?['total_non_cash_sales']),
        totalOmzet = _i(j['ringkasan']?['total_omzet']),
        totalSelisihCash = _i(j['ringkasan']?['total_selisih_cash']);
}

// ===== Langganan / billing (padanan src/types/index.ts Billing dkk) =====
class SubscriptionSetting {
  final int priceMonthly, price3Months, price6Months, priceYearly, priceBusinessMonthly, priceBusinessYearly;
  SubscriptionSetting.fromJson(Map<String, dynamic> j)
      : priceMonthly = _i(j['PRICE_MONTHLY']),
        price3Months = _i(j['PRICE_3_MONTHS']),
        price6Months = _i(j['PRICE_6_MONTHS']),
        priceYearly = _i(j['PRICE_YEARLY']),
        priceBusinessMonthly = _i(j['PRICE_BUSINESS_MONTHLY']),
        priceBusinessYearly = _i(j['PRICE_BUSINESS_YEARLY']);
}

class SubscriptionPayment {
  final int id, totalBayar;
  final String paket, targetPlan, status;
  final String? createdAt, snapRedirectUrl;
  SubscriptionPayment.fromJson(Map<String, dynamic> j)
      : id = _i(j['ID']),
        paket = '${j['PAKET'] ?? ''}',
        targetPlan = '${j['TARGET_PLAN'] ?? ''}',
        totalBayar = _i(j['TOTAL_BAYAR']),
        status = '${j['STATUS'] ?? ''}',
        createdAt = _s(j['CREATED_AT']),
        snapRedirectUrl = _s(j['SNAP_REDIRECT_URL']);
}

class Billing {
  final String plan;
  final String? proExpiresAt;
  final List<SubscriptionPayment> payments;
  final SubscriptionPayment? latest;
  Billing.fromJson(Map<String, dynamic> j)
      : plan = '${j['plan'] ?? 'FREE'}',
        proExpiresAt = _s(j['pro_expires_at']),
        payments = ((j['payments'] as List?) ?? [])
            .map((e) => SubscriptionPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
        latest = j['latest'] == null ? null : SubscriptionPayment.fromJson(j['latest'] as Map<String, dynamic>);
}
