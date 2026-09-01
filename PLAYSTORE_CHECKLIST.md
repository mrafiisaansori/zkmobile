# Checklist Siap Rilis — Zona Kasir (Play Store)

Disiapkan supaya begitu ada dana $25 buat akun Google Play Console, submit-nya tinggal isi form, tidak perlu mikir teknis lagi.

## ✅ Sudah beres (sesi ini)

- **Keystore rilis**: `android/app/upload-keystore.jks` + `android/key.properties` — build release sekarang otomatis ditandatangani pakai key ini (bukan debug key lagi). **BACKUP FILE INI DI TEMPAT AMAN** (Google Drive/USB terpisah). Kalau hilang, app **tidak bisa** diupdate lagi di Play Store dengan listing yang sama — harus bikin listing baru dari nol.
  - Alias: `upload`
  - Password (store & key sama): `PD5SAPEUn7LZxw9jKM9N`
  - Berlaku sampai: 14 Januari 2054
- **App Bundle (.aab)** — format wajib Play Store (bukan .apk) — sudah bisa dibuild:
  ```
  flutter build appbundle --release
  ```
  Hasil: `build/app/outputs/bundle/release/app-release.aab`
- **Kebijakan Privasi** — sudah dibuat & di-publish, wajib diisi di form Play Console: https://claude.ai/code/artifact/1743943a-0c14-4979-abc8-7cbb23283edc (klik tombol Share di halaman itu dulu biar bisa diakses reviewer Google — default-nya privat)
- **Package name**: `com.zonakasir.zkkasir` (tidak bisa diganti setelah publish pertama, sudah dicek unik)

## 📝 Belum — perlu kamu isi manual saat submit

### Akun & pembayaran
- [ ] Daftar Google Play Console: https://play.google.com/console/signup (bayar $25 sekali, bukan langganan)
- [ ] Verifikasi identitas developer (KTP, butuh 1-2 hari kadang)

### Store listing (teks)
- [ ] **Nama app**: `Zona Kasir` (maks 30 karakter)
- [ ] **Deskripsi singkat** (maks 80 karakter) — draf:
  > Aplikasi kasir (POS) offline-ready untuk toko & UMKM Anda
- [ ] **Deskripsi lengkap** (maks 4000 karakter) — draf ada di bawah
- [ ] **Kategori**: Bisnis (Business)
- [ ] **Email kontak**: (isi email support kamu)
- [ ] **Kebijakan privasi**: pakai link artifact di atas, atau pindahkan ke domain sendiri kalau sudah punya

### Aset visual (wajib)
- [ ] **Ikon app** 512×512 px — sudah ada di `assets/icon_launcher.png`, tinggal resize/export ke 512×512 PNG kalau ukurannya beda
- [ ] **Feature graphic** 1024×500 px — banner promosi di halaman listing, belum ada, perlu didesain (bisa saya bantu bikin kalau mau)
- [ ] **Screenshot minimal 2, ideal 4-8** — per form factor:
  - Ponsel: minimal 2 (rasio 16:9 atau 9:16)
  - Tablet 7" & 10" (opsional tapi disarankan karena app ini punya layout tablet khusus)
  - Cara ambil cepat: `adb exec-out screencap -p > screenshot.png` dari HP/emulator yang sudah kita pakai testing

### Content rating & compliance (diisi lewat form, bukan file)
- [ ] Isi kuesioner **Content Rating** (IARC) — app ini kemungkinan dapat rating "Everyone/3+", tidak ada konten sensitif
- [ ] **Data safety form** — isi sesuai tabel di kebijakan privasi (username/password untuk login, data transaksi, foto opsional, lokasi untuk Bluetooth scan)
- [ ] Declare **target API level** sesuai kebijakan Play terbaru (Flutter build tool otomatis pakai versi yang direkomendasikan, biasanya sudah aman)

### Rilis
- [ ] Mulai dari **Internal testing** atau **Closed testing** dulu (tidak kena review penuh, cepat, bisa langsung invite diri sendiri untuk uji coba) sebelum ke **Production**
- [ ] Upload `app-release.aab` yang sudah dibuild
- [ ] Isi **release notes** (catatan rilis versi 1.0.0)

## Draf deskripsi lengkap (Play Store)

```
Zona Kasir — Aplikasi Kasir Modern untuk Bisnis Anda

Kelola transaksi penjualan, stok, dan laporan bisnis langsung dari HP atau tablet Anda. Zona Kasir dirancang untuk pemilik toko, kafe, dan UMKM yang butuh sistem kasir simpel, cepat, dan tetap bisa jualan walau internet putus.

FITUR KASIR
• Transaksi cepat dengan grid produk & scan barcode
• Mode offline — tetap bisa checkout tanpa internet, sinkron otomatis saat online kembali
• Open Bill & Split Bill untuk restoran/kafe
• Cetak struk via printer thermal Bluetooth
• Buka/tutup kas dengan rekap otomatis

UNTUK PEMILIK TOKO (Admin)
• Kelola produk, kategori, varian, dan stok
• Pembelian & retur barang ke supplier
• Laporan transaksi, keuangan, dan closing kasir
• Kelola member, voucher, dan pengguna/staff
• Katalog produk online

Didesain untuk ponsel maupun tablet, dengan tampilan yang menyesuaikan otomatis.

Upgrade ke paket PRO untuk fitur lebih lengkap: multi-kasir, voucher, pajak, laporan mendalam, dan lainnya.
```

## File penting yang jangan sampai hilang

| File | Kenapa penting |
|---|---|
| `android/app/upload-keystore.jks` | Tanpa ini, app tidak bisa diupdate lagi setelah publish |
| `android/key.properties` | Password buat buka keystore di atas |

Rekomendasi: copy dua file ini ke Google Drive/cloud storage pribadi SEKARANG, jangan tunggu sampai mau publish.
