import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/produk_picker_sheet.dart';
import '../../shared/widgets/sheet_common.dart';
import '../data/retur_repository.dart';

const _kondisiOptions = ['Rusak', 'Salah kirim', 'Kedaluwarsa', 'Tidak sesuai', 'Lainnya'];

class _ItemRow {
  Produk? produk;
  final harga = TextEditingController();
  final qty = TextEditingController();
  final alasan = TextEditingController();
  String? kondisi;
}

// Padanan lib/admin_retur_form_page.dart lama — halaman penuh (bukan sheet)
// karena daftar item bisa panjang & butuh ruang untuk tambah/hapus baris.
// Item retur TIDAK mengubah stok sampai dokumennya diselesaikan (sama seperti
// Pembelian, tapi arah stoknya berkurang, bukan bertambah). Submit
// (draft/selesaikan) dilakukan lewat FormSubmitCubit<int> — hasilnya ID
// retur (baru dibuat atau yang sedang diubah).
//
// ponytail: sidebar tablet (AdminSidebar) belum dipasang di sini, sama
// seperti AdminPembelianFormPage — AdminShell belum dipindah ke features/
// (batch migrasi terpisah). Halaman ini masih bisa dipakai penuh lewat
// tombol "Kembali", cuma belum ada shortcut pindah tab dari sini seperti
// versi lama.
class AdminReturFormPage extends StatefulWidget {
  final Retur? retur;
  const AdminReturFormPage({super.key, this.retur});
  @override
  State<AdminReturFormPage> createState() => _AdminReturFormPageState();
}

class _AdminReturFormPageState extends State<AdminReturFormPage> {
  final _repo = ReturRepository();
  final _formCubit = FormSubmitCubit<int>();
  late final _noNota = TextEditingController(text: widget.retur?.noNota ?? '');
  late DateTime _tanggal = DateTime.tryParse(widget.retur?.tanggal ?? '') ?? DateTime.now();
  late final _catatan = TextEditingController(text: widget.retur?.catatan ?? '');
  List<Supplier> _supplier = [];
  List<Pembelian> _pembelianOptions = [];
  int? _idSupplier, _idPembelian;
  final List<_ItemRow> _items = [];
  bool _loadingRef = true;

  @override
  void initState() {
    super.initState();
    _idSupplier = widget.retur?.idSupplier;
    _idPembelian = widget.retur?.idPembelian;
    if (widget.retur != null && widget.retur!.detail.isNotEmpty) {
      for (final d in widget.retur!.detail) {
        final row = _ItemRow()
          ..produk = Produk.raw(d.idProduk, d.namaProduk ?? 'Produk ${d.idProduk}', 0, 0)
          ..qty.text = '${d.qty}'
          ..harga.text = '${d.harga ?? 0}'
          ..alasan.text = d.alasan ?? ''
          ..kondisi = d.kondisi;
        _items.add(row);
      }
    } else {
      _items.add(_ItemRow());
    }
    _loadRef();
  }

  Future<void> _loadRef() async {
    try {
      final results = await Future.wait([_repo.suppliers(), _repo.pembelianSelesai()]);
      _supplier = results[0] as List<Supplier>;
      _pembelianOptions = results[1] as List<Pembelian>;
      if (widget.retur?.noNotaPembelian != null &&
          !_pembelianOptions.any((p) => p.id == _idPembelian)) {
        _pembelianOptions = [
          Pembelian.fromJson({
            'ID': _idPembelian,
            'NO_NOTA': widget.retur!.noNotaPembelian,
            'STATUS': 1,
          }),
          ..._pembelianOptions,
        ];
      }
    } catch (_) {
      // Dropdown supplier/pembelian opsional — gagal muat tidak menghalangi form.
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
      it.alasan.dispose();
    }
    _formCubit.close();
    super.dispose();
  }

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
      row.alasan.dispose();
      _items.remove(row);
    });
  }

  Future<int> _doSubmit({required bool selesaikan}) async {
    final clean = _items.where((it) => it.produk != null && (int.tryParse(it.qty.text) ?? 0) > 0).toList();
    final data = {
      'no_nota': _noNota.text.trim(),
      'tanggal': _tanggal.toIso8601String().substring(0, 10),
      'id_supplier': _idSupplier,
      'id_pembelian': _idPembelian,
      if (_catatan.text.trim().isNotEmpty) 'catatan': _catatan.text.trim(),
      'items': [
        for (final it in clean)
          {
            'id_produk': it.produk!.id,
            'qty': int.tryParse(it.qty.text) ?? 0,
            if (it.alasan.text.trim().isNotEmpty) 'alasan': it.alasan.text.trim(),
            if (it.kondisi != null) 'kondisi': it.kondisi,
            'harga': it.harga.text.isEmpty ? null : parseRupiah(it.harga.text),
          },
      ],
    };
    int id = widget.retur?.id ?? 0;
    if (widget.retur == null) {
      id = await _repo.create(data);
    } else {
      await _repo.update(id, data);
    }
    if (selesaikan) await _repo.selesaikan(id);
    return id;
  }

  void _submit({required bool selesaikan}) {
    if (_noNota.text.trim().isEmpty) {
      toastError(context, 'Nomor retur wajib diisi');
      return;
    }
    final clean = _items.where((it) => it.produk != null && (int.tryParse(it.qty.text) ?? 0) > 0).toList();
    if (clean.isEmpty) {
      toastError(context, 'Tambahkan minimal 1 item');
      return;
    }
    _formCubit.submit(() => _doSubmit(selesaikan: selesaikan));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocListener<FormSubmitCubit<int>, FormSubmitState<int>>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            toastOk(context,
                widget.retur == null ? 'Draft retur disimpan' : 'Retur diperbarui');
            Navigator.pop(context, true);
          } else if (state.status == FormStatus.error && state.error != null) {
            toastError(context, state.error!);
          }
        },
        // Builder: context di sini berada DI BAWAH BlocProvider.value di atas,
        // beda dari `context` milik build() yang berada di ATAS-nya — kalau
        // _buildScaffold dipanggil langsung pakai context milik build(),
        // context.watch<FormSubmitCubit<int>> di dalamnya akan lempar
        // ProviderNotFoundException (bug yang sama persis pernah kejadian di
        // KasirShell — lihat catatan di kasir_shell.dart).
        child: Builder(builder: (context) => _buildScaffold(context)),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final editing = widget.retur != null;
    final tgl = _tanggal.toIso8601String().substring(0, 10);
    final saving = context.watch<FormSubmitCubit<int>>().state.status == FormStatus.submitting;

    final hero = HeroShell(
      titleOverride: editing ? 'Ubah Retur' : 'Buat Retur',
      subtitleOverride: 'Pengembalian barang ke supplier',
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
                  Text(editing ? 'Ubah Retur' : 'Buat Retur',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
                  const SizedBox(height: 16),
                  const FieldLabel('Nomor retur'),
                  TextField(
                      controller: _noNota,
                      style: TextStyle(color: fg),
                      decoration: sheetInput('mis. RTR-001', dark: dark)),
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
                      const DropdownMenuItem(value: null, child: Text('Tanpa supplier')),
                      for (final s in _supplier) DropdownMenuItem(value: s.id, child: Text(s.nama)),
                    ],
                    onChanged: (v) => setState(() => _idSupplier = v),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Pembelian asal (opsional)'),
                  DropdownButtonFormField<int?>(
                    initialValue: _idPembelian,
                    isExpanded: true,
                    style: TextStyle(color: fg, fontSize: 14),
                    dropdownColor: dark ? ZK.cardDark : Colors.white,
                    decoration: sheetInput('Pilih pembelian', dark: dark),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tanpa pembelian asal')),
                      for (final p in _pembelianOptions)
                        DropdownMenuItem(value: p.id, child: Text(p.noNota)),
                    ],
                    onChanged: (v) => setState(() => _idPembelian = v),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Catatan (opsional)'),
                  TextField(
                      controller: _catatan,
                      style: TextStyle(color: fg),
                      decoration: sheetInput('Catatan tambahan', dark: dark)),
                  const SizedBox(height: 18),
                  Text('Item Retur', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
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
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: dark ? ZK.amber50.withValues(alpha: 0.15) : ZK.amber50, borderRadius: r12),
                    child: Text(
                        'Stok TIDAK berubah saat draft. Stok baru berkurang ketika retur diselesaikan. Pembatalan retur selesai akan mengembalikan stok.',
                        style: TextStyle(fontSize: 11.5, color: ZK.amber700)),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: saving ? null : () => _submit(selesaikan: false),
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
                      onPressed: saving ? null : () => _submit(selesaikan: true),
                      icon: saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Selesaikan Retur',
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
                    Icon(Icons.inventory_2_outlined, size: 16, color: dark ? Colors.white60 : ZK.slate400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(row.produk?.nama ?? 'Pilih produk',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: row.produk == null ? (dark ? Colors.white60 : ZK.slate500) : fg)),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: dark ? Colors.white60 : ZK.slate400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: row.qty,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: fg, fontSize: 13),
                    decoration: sheetInput('Qty retur', dark: dark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.harga,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    style: TextStyle(color: fg, fontSize: 13),
                    decoration: sheetInput('Nilai/harga', prefix: 'Rp ', dark: dark),
                  ),
                ),
                IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _removeRow(row),
                    icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: row.kondisi,
              isExpanded: true,
              style: TextStyle(color: fg, fontSize: 13),
              dropdownColor: dark ? ZK.cardDark : Colors.white,
              decoration: sheetInput('Kondisi barang', dark: dark),
              items: [
                const DropdownMenuItem(value: null, child: Text('Pilih')),
                for (final k in _kondisiOptions) DropdownMenuItem(value: k, child: Text(k)),
              ],
              onChanged: (v) => setState(() => row.kondisi = v),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: row.alasan,
                style: TextStyle(color: fg, fontSize: 13),
                decoration: sheetInput('Alasan retur (mis. kemasan rusak)', dark: dark)),
          ],
        ),
      );
}
