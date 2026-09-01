import 'package:flutter/material.dart';
import 'admin_produk_picker.dart';
import 'admin_shell.dart';
import 'api.dart';
import 'login_page.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

class _ItemRow {
  Produk? produk;
  final harga = TextEditingController();
  final qty = TextEditingController();
}

// Padanan modal form Pembelian di web — halaman penuh (bukan sheet) karena
// daftar item bisa panjang & butuh ruang untuk tambah/hapus baris.
class AdminPembelianFormPage extends StatefulWidget {
  final Pembelian? pembelian;
  const AdminPembelianFormPage({super.key, this.pembelian});
  @override
  State<AdminPembelianFormPage> createState() => _AdminPembelianFormPageState();
}

class _AdminPembelianFormPageState extends State<AdminPembelianFormPage> {
  late final _noNota = TextEditingController(text: widget.pembelian?.noNota ?? '');
  late DateTime _tanggal =
      DateTime.tryParse(widget.pembelian?.tanggal ?? '') ?? DateTime.now();
  late final _catatan = TextEditingController(text: widget.pembelian?.catatan ?? '');
  List<Supplier> _supplier = [];
  int? _idSupplier;
  final List<_ItemRow> _items = [];
  bool _loadingRef = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _idSupplier = widget.pembelian?.idSupplier;
    if (widget.pembelian != null && widget.pembelian!.detail.isNotEmpty) {
      for (final d in widget.pembelian!.detail) {
        final row = _ItemRow()
          ..produk = Produk.raw(d.idProduk, d.namaProduk ?? 'Produk ${d.idProduk}', 0, 0)
          ..harga.text = '${d.hargaBeli}'
          ..qty.text = '${d.qty}';
        _items.add(row);
      }
    } else {
      _items.add(_ItemRow());
    }
    _loadRef();
  }

  Future<void> _loadRef() async {
    try {
      _supplier = await Api.suppliers();
    } catch (_) {
      // Dropdown supplier opsional — gagal muat tidak menghalangi form.
    } finally {
      if (mounted) setState(() => _loadingRef = false);
    }
  }

  @override
  void dispose() {
    _noNota.dispose();
    _catatan.dispose();
    for (final it in _items) {
      it.harga.dispose();
      it.qty.dispose();
    }
    super.dispose();
  }

  int get _total => _items.fold<int>(
      0, (s, it) => s + (parseRupiah(it.harga.text) * (int.tryParse(it.qty.text) ?? 0)));

  Future<void> _pickTanggal() async {
    final d = await showDatePicker(
        context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDate: _tanggal);
    if (d != null) setState(() => _tanggal = d);
  }

  Future<void> _pickProdukFor(_ItemRow row) async {
    final p = await pickProduk(context);
    if (p != null) setState(() => row.produk = p);
  }

  void _addRow() => setState(() => _items.add(_ItemRow()));
  void _removeRow(_ItemRow row) {
    if (_items.length == 1) return;
    setState(() {
      row.harga.dispose();
      row.qty.dispose();
      _items.remove(row);
    });
  }

  Future<void> _submit({required bool selesaikan}) async {
    if (_noNota.text.trim().isEmpty) {
      toastError(context, 'Nomor nota wajib diisi');
      return;
    }
    final clean = _items.where((it) => it.produk != null && (int.tryParse(it.qty.text) ?? 0) > 0).toList();
    if (clean.isEmpty) {
      toastError(context, 'Tambahkan minimal 1 item produk');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'no_nota': _noNota.text.trim(),
        'tanggal': _tanggal.toIso8601String().substring(0, 10),
        'id_supplier': _idSupplier,
        if (_catatan.text.trim().isNotEmpty) 'catatan': _catatan.text.trim(),
        'items': [
          for (final it in clean)
            {
              'id_produk': it.produk!.id,
              'harga_beli': parseRupiah(it.harga.text),
              'qty': int.tryParse(it.qty.text) ?? 0,
            },
        ],
      };
      int? id = widget.pembelian?.id;
      if (widget.pembelian == null) {
        id = await Api.createPembelian(data);
      } else {
        await Api.updatePembelian(id!, data);
      }
      if (selesaikan) {
        await Api.selesaikanPembelian(id);
        if (mounted) toastOk(context, 'Pembelian selesai, stok & harga beli diperbarui');
      } else {
        if (mounted) toastOk(context, 'Draft pembelian disimpan');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await Session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final editing = widget.pembelian != null;
    final tgl = _tanggal.toIso8601String().substring(0, 10);

    final hero = HeroShell(
      titleOverride: editing ? 'Ubah Pembelian' : 'Buat Pembelian',
      subtitleOverride: 'Barang masuk dari supplier',
      child: SafeArea(
        top: false,
        bottom: false,
        child: _loadingRef
            ? const Center(child: CircularProgressIndicator(color: ZK.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: r12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 18, color: fg),
                          const SizedBox(width: 6),
                          Text('Kembali',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(editing ? 'Ubah Pembelian' : 'Buat Pembelian',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
                  const SizedBox(height: 16),
                  const FieldLabel('Nomor nota/invoice'),
                  TextField(
                      controller: _noNota,
                      style: TextStyle(color: fg),
                      decoration: sheetInput('mis. INV-001', dark: dark)),
                  const SizedBox(height: 14),
                  const FieldLabel('Tanggal'),
                  InkWell(
                    onTap: _pickTanggal,
                    borderRadius: r14,
                    child: InputDecorator(
                      decoration: sheetInput('', dark: dark),
                      child: Text(tgl, style: TextStyle(color: fg, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Supplier (opsional)'),
                  DropdownButtonFormField<int?>(
                    initialValue: _idSupplier,
                    isExpanded: true,
                    style: TextStyle(color: fg, fontSize: 14),
                    dropdownColor: dark ? ZK.cardDark : Colors.white,
                    decoration: sheetInput('Pilih supplier', dark: dark),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Tanpa supplier —')),
                      for (final s in _supplier) DropdownMenuItem(value: s.id, child: Text(s.nama)),
                    ],
                    onChanged: (v) => setState(() => _idSupplier = v),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Catatan (opsional)'),
                  TextField(
                      controller: _catatan,
                      style: TextStyle(color: fg),
                      decoration: sheetInput('Catatan tambahan', dark: dark)),
                  const SizedBox(height: 18),
                  Text('Item Pembelian',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                  const SizedBox(height: 10),
                  for (final row in _items) _itemCard(row, fg, muted, dark),
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah item'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: ZK.primary,
                        side: const BorderSide(color: ZK.brand200),
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Pembelian', style: TextStyle(fontSize: 13, color: muted)),
                      Text(rupiah(_total),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ZK.primary)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _submit(selesaikan: false),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.primary,
                          side: const BorderSide(color: ZK.brand200),
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                      child: const Text('Simpan Draft',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _submit(selesaikan: true),
                      icon: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Selesaikan & Tambah Stok',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                          backgroundColor: ZK.primary,
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ],
              ),
      ),
    );

    if (isTablet(context)) {
      return Scaffold(
        backgroundColor: dark ? ZK.bgDark : ZK.background,
        body: Row(
          children: [
            AdminSidebar(
              selected: 10, // index Pembelian Barang di grup Operasional
              onSelect: (i) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                AdminShellState.current?.select(i);
              },
              onLogout: _logout,
            ),
            Expanded(child: hero),
          ],
        ),
      );
    }
    return Scaffold(backgroundColor: dark ? ZK.bgDark : ZK.background, body: hero);
  }

  Widget _itemCard(_ItemRow row, Color fg, Color muted, bool dark) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _pickProdukFor(row),
              borderRadius: r12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                    borderRadius: r12, border: Border.all(color: dark ? ZK.lineDark : ZK.brand200)),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: dark ? Colors.white54 : ZK.slate400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(row.produk?.nama ?? 'Pilih produk',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: row.produk == null ? (dark ? Colors.white38 : ZK.slate400) : fg)),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: dark ? Colors.white38 : ZK.slate400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.harga,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: fg, fontSize: 13),
                    decoration: sheetInput('Harga beli', prefix: 'Rp ', dark: dark),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: row.qty,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: fg, fontSize: 13),
                    decoration: sheetInput('Qty', dark: dark),
                  ),
                ),
                IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _removeRow(row),
                    icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                  rupiah(parseRupiah(row.harga.text) * (int.tryParse(row.qty.text) ?? 0)),
                  style: TextStyle(fontSize: 12, color: muted)),
            ),
          ],
        ),
      );
}
