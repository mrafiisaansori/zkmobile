import '_util.dart';
import 'sales.dart';

// ===== Dashboard admin (padanan DashboardSummary di web src/types/index.ts) =====
class StokMenipisItem {
  final int id, stok;
  final String nama;
  StokMenipisItem.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        stok = i(j['STOK']);
}

class ProdukTerlaris {
  final int idProduk, qty, omzet;
  final String nama;
  ProdukTerlaris.fromJson(Map<String, dynamic> j)
      : idProduk = i(j['id_produk']),
        nama = '${j['nama'] ?? ''}',
        qty = i(j['qty']),
        omzet = i(j['omzet']);
}

class ChartBulan {
  final int bulan, omzet, laba;
  ChartBulan.fromJson(Map<String, dynamic> j)
      : bulan = i(j['bulan']),
        omzet = i(j['omzet']),
        laba = i(j['laba']);
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
        transaksiHariIni = i(j['transaksi_hari_ini']),
        pendapatanHariIni = i(j['pendapatan_hari_ini']),
        labaHariIni = i(j['laba_hari_ini']),
        ppnHariIni = i(j['ppn_hari_ini']),
        serviceHariIni = i(j['service_hari_ini']),
        totalDibayarHariIni = i(j['total_dibayar_hari_ini']),
        rataRataTransaksi = i(j['rata_rata_transaksi']),
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
