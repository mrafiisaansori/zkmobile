import '_util.dart';

class Produk {
  final int id, stok, hargaJual;
  final String nama;
  final String? foto, satuan;
  // Dipakai halaman admin (form edit produk) — kasir tidak butuh ini.
  final int idKategori, hargaBeli;
  final int? idSatuan;
  final String? barcode;
  Produk.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        stok = i(j['STOK']),
        hargaJual = i(j['HARGA_JUAL']),
        satuan = s(j['satuan']?['NAMA']),
        // Urutan kandidat sama dengan utils/image.ts di web.
        foto = s(j['FOTO_URL']) ??
            s(j['FOTO']) ??
            s(j['image_url']) ??
            s(j['foto_url']),
        idKategori = i(j['ID_KATEGORI']),
        hargaBeli = i(j['HARGA_BELI']),
        idSatuan = j['ID_SATUAN'] == null ? null : i(j['ID_SATUAN']),
        barcode = s(j['BARCODE']);

  // Produk sintetis untuk item open bill (detail bill tidak membawa data produk penuh).
  Produk.raw(this.id, this.nama, this.hargaJual, this.stok,
      {this.foto, this.satuan, this.idKategori = 0, this.hargaBeli = 0, this.idSatuan, this.barcode});
}

class Kategori {
  final int id;
  final String deskripsi;
  Kategori.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        deskripsi = '${j['DESKRIPSI'] ?? ''}';
}

class Satuan {
  final int id;
  final String nama;
  Satuan.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}';
}

class Supplier {
  final int id;
  final String nama;
  final String? alamat, noTelp, email, catatan;
  final int status;
  Supplier.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}',
        alamat = s(j['ALAMAT']),
        noTelp = s(j['NO_TELP']),
        email = s(j['EMAIL']),
        catatan = s(j['CATATAN']),
        status = j['STATUS'] == null ? 1 : i(j['STATUS']);
}
