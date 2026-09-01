import 'dart:async';
import 'package:flutter/material.dart';
import 'admin_pembelian_form_page.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

const _statusLabel = {0: 'Draft', 1: 'Selesai', 2: 'Dibatalkan'};

(Color, Color) statusTone(int status, bool dark) => switch (status) {
      1 => (dark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
          dark ? Colors.greenAccent : const Color(0xFF047857)),
      2 => (ZK.rose50, ZK.rose),
      _ => (ZK.amber50, ZK.amber700),
    };

// Padanan src/app/admin/pembelian/page.tsx — barang masuk / restok dari
// supplier. Draft bisa diedit/dihapus/diselesaikan; setelah Selesai stok &
// harga beli sudah terkunci (dokumen read-only, aksi cuma "Lihat").
class AdminPembelianPage extends StatefulWidget {
  const AdminPembelianPage({super.key});
  @override
  State<AdminPembelianPage> createState() => _AdminPembelianPageState();
}

class _AdminPembelianPageState extends State<AdminPembelianPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _status;
  List<Pembelian> _data = [];
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
      final r = await Api.pembelian(search: _search.text, status: _status == null ? null : int.parse(_status!));
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
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AdminPembelianFormPage()));
    if (ok == true) _load();
  }

  Future<void> _ubah(Pembelian p) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AdminPembelianFormPage(pembelian: p)));
    if (ok == true) _load();
  }

  Future<void> _lihat(Pembelian p) async {
    try {
      final full = await Api.pembelianDetail(p.id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PembelianDetailSheet(pembelian: full),
      );
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _selesaikan(Pembelian p) async {
    final ok = await confirmDialog(context,
        title: 'Selesaikan pembelian?',
        message:
            'Selesaikan "${p.noNota}"? Stok akan ditambah & harga beli diperbarui. Dokumen akan terkunci.');
    if (!ok) return;
    try {
      await Api.selesaikanPembelian(p.id);
      if (mounted) toastOk(context, 'Pembelian selesai, stok diperbarui');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Pembelian p) async {
    final ok = await confirmDialog(context,
        title: 'Hapus draft?', message: 'Hapus draft "${p.noNota}"?', danger: true);
    if (!ok) return;
    try {
      await Api.deletePembelian(p.id);
      if (mounted) toastOk(context, 'Pembelian dihapus');
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
                        hintText: 'Cari nomor nota...',
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
                        icon: Icons.shopping_cart_outlined,
                        title: 'Belum ada pembelian',
                        description: 'Catat barang masuk dari supplier di sini.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final p = _data[i];
                            final (bg, tone) = statusTone(p.status, dark);
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
                                    child: const Icon(Icons.shopping_cart_outlined, color: ZK.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.noNota,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                        const SizedBox(height: 2),
                                        Text(
                                            [
                                              if (p.tanggal != null) p.tanggal!,
                                              p.namaSupplier ?? 'Tanpa supplier',
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: muted)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration:
                                              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                                          child: Text(_statusLabel[p.status] ?? '-',
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
                                          onPressed: () => _lihat(p),
                                          tooltip: 'Lihat',
                                          icon: Icon(Icons.visibility_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      if (p.status == 0) ...[
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _ubah(p),
                                            tooltip: 'Ubah',
                                            icon: Icon(Icons.edit_outlined,
                                                size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _selesaikan(p),
                                            tooltip: 'Selesaikan',
                                            icon: const Icon(Icons.check_circle_outline,
                                                size: 18, color: Color(0xFF047857))),
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _hapus(p),
                                            tooltip: 'Hapus',
                                            icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                                      ],
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

class _PembelianDetailSheet extends StatelessWidget {
  final Pembelian pembelian;
  const _PembelianDetailSheet({required this.pembelian});

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
              title: pembelian.noNota,
              subtitle: pembelian.namaSupplier ?? 'Tanpa supplier',
              icon: Icons.shopping_cart_outlined,
            ),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pembelian.catatan != null) ...[
                      Text(pembelian.catatan!, style: TextStyle(fontSize: 12, color: muted)),
                      const SizedBox(height: 10),
                    ],
                    for (final d in pembelian.detail)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(d.namaProduk ?? 'Produk ${d.idProduk}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                            ),
                            Text('${d.qty} × ${rupiah(d.hargaBeli)}',
                                style: TextStyle(fontSize: 12, color: muted)),
                            const SizedBox(width: 8),
                            Text(rupiah(d.subtotal),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 13, color: muted)),
                        Text(rupiah(pembelian.total),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: fg)),
                      ],
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
