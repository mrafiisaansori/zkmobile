import 'dart:async';
import 'package:flutter/material.dart';
import 'admin_pembelian_page.dart' show statusTone;
import 'admin_retur_form_page.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

const _statusLabel = {0: 'Draft', 1: 'Selesai', 2: 'Dibatalkan'};

// Padanan src/app/admin/retur/page.tsx — pengembalian barang ke supplier.
// Draft: edit/selesaikan/hapus. Selesai: batal/void (stok yang sudah
// dikurangi dikembalikan). Beda dari Pembelian yang tidak punya aksi batal.
class AdminReturPage extends StatefulWidget {
  const AdminReturPage({super.key});
  @override
  State<AdminReturPage> createState() => _AdminReturPageState();
}

class _AdminReturPageState extends State<AdminReturPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _status;
  List<Retur> _data = [];
  bool _loading = true;

  static const _tabs = [
    (null, 'Semua'),
    ('0', 'Draft'),
    ('1', 'Selesai'),
    ('2', 'Dibatalkan'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.retur(search: _search.text, status: _status == null ? null : int.parse(_status!));
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _tambah() async {
    final ok =
        await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AdminReturFormPage()));
    if (ok == true) _load();
  }

  Future<void> _ubah(Retur r) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AdminReturFormPage(retur: r)));
    if (ok == true) _load();
  }

  Future<void> _lihat(Retur r) async {
    try {
      final full = await Api.returDetail(r.id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReturDetailSheet(retur: full),
      );
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _selesaikan(Retur r) async {
    final ok = await confirmDialog(context,
        title: 'Selesaikan retur?',
        message: 'Selesaikan "${r.noNota}"? Stok akan dikurangi sesuai item. Dokumen akan terkunci.');
    if (!ok) return;
    try {
      await Api.selesaikanRetur(r.id);
      if (mounted) toastOk(context, 'Retur selesai, stok dikurangi');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _batalkan(Retur r) async {
    final ok = await confirmDialog(context,
        title: 'Batalkan / void retur?',
        message: 'Batalkan "${r.noNota}"? Stok yang sebelumnya dikurangi akan dikembalikan.',
        danger: true);
    if (!ok) return;
    try {
      await Api.batalRetur(r.id);
      if (mounted) toastOk(context, 'Retur dibatalkan, stok dikembalikan');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Retur r) async {
    final ok = await confirmDialog(context,
        title: 'Hapus draft?', message: 'Hapus draft "${r.noNota}"?', danger: true);
    if (!ok) return;
    try {
      await Api.deleteRetur(r.id);
      if (mounted) toastOk(context, 'Retur dihapus');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearch,
                      style: TextStyle(color: dark ? Colors.white : ZK.ink),
                      decoration: InputDecoration(
                        hintText: 'Cari nomor retur...',
                        hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: dark ? Colors.white54 : ZK.slate400),
                        filled: true,
                        fillColor: dark ? ZK.cardDark : Colors.white,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: r12, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius: r12, borderSide: BorderSide(color: ZK.primary, width: 1.6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _tambah,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Buat'),
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary,
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final t in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _status = t.$1);
                        _load();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _status == t.$1 ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: _status == t.$1 ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
                        ),
                        child: Text(t.$2,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _status == t.$1 ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : _data.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_return_outlined,
                        title: 'Belum ada retur',
                        description: 'Catat pengembalian barang ke supplier di sini.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final r = _data[i];
                            final (bg, tone) = statusTone(r.status, dark);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dark ? ZK.cardDark : Colors.white,
                                borderRadius: r14,
                                border: Border.all(color: lineColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                        color: dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
                                        shape: BoxShape.circle),
                                    child:
                                        const Icon(Icons.assignment_return_outlined, color: ZK.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.noNota,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                        const SizedBox(height: 2),
                                        Text(
                                            [
                                              if (r.tanggal != null) r.tanggal!,
                                              r.namaSupplier ?? 'Tanpa supplier',
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: muted)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration:
                                              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                                          child: Text(_statusLabel[r.status] ?? '-',
                                              style: TextStyle(
                                                  fontSize: 10.5, fontWeight: FontWeight.w700, color: tone)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _lihat(r),
                                          tooltip: 'Lihat',
                                          icon: Icon(Icons.visibility_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      if (r.status == 0) ...[
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _ubah(r),
                                            tooltip: 'Ubah',
                                            icon: Icon(Icons.edit_outlined,
                                                size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _selesaikan(r),
                                            tooltip: 'Selesaikan',
                                            icon: const Icon(Icons.check_circle_outline,
                                                size: 18, color: Color(0xFF047857))),
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _hapus(r),
                                            tooltip: 'Hapus',
                                            icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                                      ],
                                      if (r.status == 1)
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _batalkan(r),
                                            tooltip: 'Batalkan / Void',
                                            icon: const Icon(Icons.block, size: 18, color: ZK.rose)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ReturDetailSheet extends StatelessWidget {
  final Retur retur;
  const _ReturDetailSheet({required this.retur});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    return Container(
      decoration: sheetBox(dark),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: retur.noNota,
              subtitle: retur.namaSupplier ?? 'Tanpa supplier',
              icon: Icons.assignment_return_outlined,
            ),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (retur.noNotaPembelian != null) ...[
                      Text('Pembelian asal: ${retur.noNotaPembelian}',
                          style: TextStyle(fontSize: 12, color: muted)),
                      const SizedBox(height: 6),
                    ],
                    if (retur.catatan != null) ...[
                      Text(retur.catatan!, style: TextStyle(fontSize: 12, color: muted)),
                      const SizedBox(height: 10),
                    ],
                    for (final d in retur.detail)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(d.namaProduk ?? 'Produk ${d.idProduk}',
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                                ),
                                Text('${d.qty} unit', style: TextStyle(fontSize: 12, color: muted)),
                              ],
                            ),
                            if (d.kondisi != null || d.alasan != null)
                              Text([if (d.kondisi != null) d.kondisi!, if (d.alasan != null) d.alasan!]
                                  .join(' · '),
                                  style: TextStyle(fontSize: 11, color: muted)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
