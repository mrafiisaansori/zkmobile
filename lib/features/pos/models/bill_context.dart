// Konteks open bill yang sedang diedit (null = transaksi langsung biasa).
class BillContext {
  final int id;
  final String? noBill;
  String customerName, tableNo, note;
  BillContext(this.id, this.noBill, this.customerName, this.tableNo, this.note);
}

class CartResult {
  final bool ok;
  final String? message;
  const CartResult(this.ok, [this.message]);
}
