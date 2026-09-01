import '_util.dart';
import 'dashboard.dart';

// ===== Laporan (padanan src/types/index.ts LaporanPenjualan/LaporanPendapatan/RekapLaporan) =====
class LaporanPenjualan {
  final int jumlahTransaksi, omzet, totalPpn, totalService, totalDibayar;
  LaporanPenjualan.fromJson(Map<String, dynamic> j)
      : jumlahTransaksi = i(j['jumlah_transaksi']),
        omzet = i(j['omzet']),
        totalPpn = i(j['total_ppn']),
        totalService = i(j['total_service']),
        totalDibayar = i(j['total_dibayar']);
}

class LaporanPendapatan {
  final int omzet, modal, laba, ppn, service, totalDibayar;
  LaporanPendapatan.fromJson(Map<String, dynamic> j)
      : omzet = i(j['omzet']),
        modal = i(j['modal']),
        laba = i(j['laba']),
        ppn = i(j['ppn']),
        service = i(j['service']),
        totalDibayar = i(j['total_dibayar']);
}

class RekapMetodeBayar {
  final String metode;
  final int jumlahTransaksi, total;
  RekapMetodeBayar.fromJson(Map<String, dynamic> j)
      : metode = '${j['metode'] ?? '-'}',
        jumlahTransaksi = i(j['jumlah_transaksi']),
        total = i(j['total']);
}

class RekapKasir {
  final String kasir;
  final int jumlahTransaksi, total;
  RekapKasir.fromJson(Map<String, dynamic> j)
      : kasir = '${j['kasir'] ?? '-'}',
        jumlahTransaksi = i(j['jumlah_transaksi']),
        total = i(j['total']);
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
      : idShift = i(j['id_shift']),
        kasir = s(j['kasir']),
        station = s(j['station']),
        bukaAt = s(j['buka_at']),
        tutupAt = s(j['tutup_at']),
        status = '${j['status'] ?? 'OPEN'}',
        modalAwal = i(j['modal_awal']),
        cashSales = i(j['cash_sales']),
        nonCashSales = i(j['non_cash_sales']),
        totalSales = i(j['total_sales']),
        expectedCash = i(j['expected_cash']),
        actualCash = j['actual_cash'] == null ? null : i(j['actual_cash']),
        selisihCash = j['selisih_cash'] == null ? null : i(j['selisih_cash']);
}

class DailyReport {
  final String tanggal;
  final int jumlahShift, totalCashSales, totalNonCashSales, totalOmzet, totalSelisihCash;
  final List<DailyReportRow> shift;
  DailyReport.fromJson(Map<String, dynamic> j)
      : tanggal = '${j['tanggal'] ?? ''}',
        jumlahShift = i(j['jumlah_shift']),
        shift = ((j['shift'] as List?) ?? [])
            .map((e) => DailyReportRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCashSales = i(j['ringkasan']?['total_cash_sales']),
        totalNonCashSales = i(j['ringkasan']?['total_non_cash_sales']),
        totalOmzet = i(j['ringkasan']?['total_omzet']),
        totalSelisihCash = i(j['ringkasan']?['total_selisih_cash']);
}
