# Laporan Lanjutan Audit #001

Tanggal: 9 Oktober 2026
Permintaan: "revisi keseluruhan" (ke-20 temuan), tanpa push.
Branch: `feat/kasir-ux`, 5 commit lokal (`10f87a5` sampai `a84f274`), **belum di-push**.

## Status per temuan

| # | Temuan | Status | Commit |
|---|---|---|---|
| 1 | "Ingat saya" palsu | Diperbaiki: tidak dicentang = token tidak disimpan, sesi hilang saat app ditutup | fase 1 |
| 2 | Error disamarkan jadi "kosong" | Diperbaiki di 11 halaman daftar admin (`RError` + "Muat ulang") | fase 1 |
| 3 | Em dash di teks UI | Diperbaiki: 0 tersisa | fase 1 |
| 4 | Latar pastel di mode gelap | Diperbaiki: `softBg()` di 26+ titik | fase 1, 2 |
| 5 | Teks kontras rendah | Diperbaiki: `white38`/`white54` 0 tersisa, teks `slate400` jadi `slate500` | fase 1 |
| 6 | Tombol "scan" berikon kamera | Diperbaiki: ikon enter + tooltip "Cari barcode" (opsi tanpa dependency) | fase 4 |
| 7 | Gradient + bayangan toggle tema | Diperbaiki: track solid, ditambah label aksesibilitas | fase 3 |
| 8 | Header ilustrasi 128px di tab kerja | Diperbaiki: `HeroShell(compact: true)` di Kasir, Open Bill, Sesi Kas, Riwayat, detail riwayat, transaksi gagal | fase 3 |
| 9 | Banner "Selamat Berjualan!" | Dihapus; diganti status sesi kas (sudah ada) | fase 3 |
| 10 | Dua kartu statistik kembar | Diganti satu angka fokus (penjualan, transaksi, rata-rata) | fase 3 |
| 11 | Palet hijau 6 versi | Diperbaiki: `ZK.success` / `successDark` / `successBg` + token slate | fase 1, 2 |
| 12 | Dua bentuk chip | Diperbaiki: filter/tab radius 12, label radius 6, pill 999 = 0 | fase 2 |
| 13 | Kartu produk di mode gelap | Diperbaiki: border gelap, produk habis hanya meredupkan foto + label "Habis" | fase 3 |
| 14 | Glow ikon menu aktif | Dihapus | fase 3 |
| 15 | Skala tipografi | Sebagian: 22 ukuran jadi 13. `TextTheme`/`ThemeExtension` sengaja tidak ditambahkan, lihat catatan | fase 2 |
| 16 | 4 salinan `sheet_common.dart` | Diperbaiki: 1 file di `lib/shared/widgets/` | fase 2 |
| 17 | Kode mati | Dihapus: `KembalianBox`, `_ComingSoonPage` | fase 5 |
| 18 | Utilitas tanggal terduplikasi | Diperbaiki: `core/theme/dates.dart` + `MaterialLocalizations` | fase 5 |
| 19 | Gambar tanpa cache | Diperbaiki: `cached_network_image` 4.0.4 di kartu produk, thumbnail, QRIS | fase 4 |
| 20 | Member di bayar open bill | Pilihan member disembunyikan di mode bill (keranjang & pembayaran) sampai backend mendukung | fase 4 |

## Angka sebelum dan sesudah

| Ukuran | Sebelum | Sesudah |
|---|---|---|
| Ukuran font berbeda | 22 | 13 |
| Em dash di teks UI | 17 | 0 |
| `white38` / `white54` | 58 | 0 |
| Radius pill `circular(999)` | 30 | 0 |
| Salinan `sheet_common.dart` | 4 (+1 parsial) | 1 |
| Literal `Color(0x..)` di luar tema | sekitar 50 | 12 (lihat catatan) |
| Ternary `dark ?` inline | 646 | 606 |
| Total diff `lib/` | | 90 file, +549 / -1026 baris |

## Catatan dan keputusan

- **#15 belum tuntas, sengaja.** Menambah `TextTheme` tanpa memigrasikan pemakai akan mengubah teks bawaan secara acak, dan `ThemeExtension` akan menjadi konfigurasi yang belum dipakai. Akses token warna terpusat sudah ada lewat `RColors.of(context)` + `okTone()` + `softBg()`. Migrasi 606 ternary sebaiknya bertahap per halaman saat halaman itu disentuh.
- **12 literal warna tersisa** memang disengaja: hijau WhatsApp di tombol chat Langganan, bayangan dan permukaan form login/lupa password, gradient brand di splash, kotak diskon cyan, warna skeleton, dan border banner sesi. Bisa ditokenkan bila ingin.
- **Aset `dashboard_banner.jpeg`** tidak dipakai lagi setelah #9. Filenya tidak dihapus (aturan: pertahankan aset).
- **#6** memakai opsi tanpa dependency. Pemindai kamera (`mobile_scanner`) tetap bisa ditambah nanti.
- **#20** butuh dukungan backend (`member_id` di `/open-bill/:id/pay` dan kolom member di open bill).

## Delivery Gate

| Butir | Status |
|---|---|
| R-02 tanpa em dash di teks UI | PASS: grep 0 baris |
| R-17 / R-36 / R-38 tanpa angka karangan | PASS: dashboard kasir memakai `total`, `jumlah` dari API; rata-rata dihitung dari keduanya |
| R-25 kontras teks | PASS untuk pola yang diaudit (`white38/54` 0, teks `slate400` diganti); ikon nonaktif tetap `slate400` |
| R-26 kontrol tanpa fungsi | PASS: "Ingat saya" terhubung, tombol cari barcode jujur |
| R-27 status kosong/muat/error | PASS untuk 11 daftar admin + laporan |
| R-29 palet | PASS: hijau satu token, abu-abu bertoken |
| R-01 / R-12 / R-13 gradient, bayangan, glow | PASS: toggle solid, glow ikon dihapus; gradient tersisa hanya scrim foto & splash brand |
| `flutter analyze` | PASS: hanya 4 info lama di `admin/**` (`use_build_context_synchronously`) |
| `flutter test` | PASS: 6/6 |
| R-03 / R-34 / R-35 dicek di perangkat (ponsel, tablet, terang, gelap, klik satu per satu) | **BELUM**: HP tidak tersambung saat revisi selesai. Wajib dicek sebelum dianggap selesai |
