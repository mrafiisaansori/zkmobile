// Konteks open bill yang sedang diedit (null = transaksi langsung biasa).
class BillContext {
  final int id;
  final String? noBill;
  String customerName, tableNo, note;
  // Member yang tersimpan di server untuk bill ini, untuk tahu apakah
  // pilihan member di keranjang belum disimpan.
  int? savedMemberId;
  BillContext(this.id, this.noBill, this.customerName, this.tableNo, this.note,
      [this.savedMemberId]);
}

class CartResult {
  final bool ok;
  final String? message;
  const CartResult(this.ok, [this.message]);
}
