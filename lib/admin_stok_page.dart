import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/stok/page.tsx — penyesuaian stok masuk/keluar per
// produk. Daftar produk dipakai ulang dari Api.produk(), bukan entity
// tersendiri (stok opname di web pun cuma modal "Sesuaikan" di atas list produk).
class AdminStokPage extends StatefulWidget {
  const AdminStokPage({super.key});
  @override
  State<AdminStokPage> createState() => _AdminStokPageState();
}

class _AdminStokPageState extends State<AdminStokPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<Produk> _data = [];
  bool _loading = true, _loadingMore = false, _lastPage = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    setState(() => append ? _loadingMore = true : _loading = true);
    try {
      final page = append ? _page + 1 : 1;
      final res = await Api.produk(search: _search.text, page: page);
      if (!mounted) return;
      setState(() {
        if (append) {
          final seen = _data.map((p) => p.id).toSet();
          _data.addAll(res.where((p) => !seen.contains(p.id)));
        } else {
          _data = res;
        }
        _page = page;
        _lastPage = res.length < 30;
      });
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => append ? _loadingMore = false : _loading = false);
    }
  }

  void _loadMore() {
    if (_loading || _loadingMore || _lastPage) return;
    _load(append: true);
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load());
  }

  Future<void> _sesuaikan(Produk p) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SesuaikanSheet(produk: p),
    );
    if (ok == true) _load();
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
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _search,
                onChanged: _onSearch,
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                decoration: InputDecoration(
                  hintText: 'Cari produk untuk penyesuaian stok...',
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : _data.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_outlined,
                        title: 'Produk tidak ditemukan',
                        description: 'Coba kata kunci lain.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: () => _load(),
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _data.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: ZK.primary))),
                              );
                            }
                            final p = _data[i];
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
                                  ProductThumb(url: p.foto, size: 52),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                        const SizedBox(height: 2),
                                        Text(rupiah(p.hargaJual), style: TextStyle(fontSize: 12, color: muted)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: p.stok <= 0
                                                  ? ZK.rose50
                                                  : p.stok <= 10
                                                      ? ZK.amber50
                                                      : (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50),
                                              borderRadius: BorderRadius.circular(999)),
                                          child: Text('Stok ${p.stok}',
                                              style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: p.stok <= 0
                                                      ? ZK.rose
                                                      : p.stok <= 10
                                                          ? ZK.amber700
                                                          : (dark ? Colors.white : ZK.brand700))),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _sesuaikan(p),
                                      tooltip: 'Sesuaikan stok',
                                      icon: Icon(Icons.swap_vert,
                                          size: 20, color: dark ? Colors.white60 : ZK.slate500)),
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

class _SesuaikanSheet extends StatefulWidget {
  final Produk produk;
  const _SesuaikanSheet({required this.produk});
  @override
  State<_SesuaikanSheet> createState() => _SesuaikanSheetState();
}

class _SesuaikanSheetState extends State<_SesuaikanSheet> {
  final _qty = TextEditingController();
  final _ket = TextEditingController();
  int _jenis = 1; // 1 = masuk (tambah), 2 = keluar (kurangi)
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _ket.dispose();
    super.dispose();
  }

  int get _qtyNum => int.tryParse(_qty.text) ?? 0;
  int get _stokAkhir => widget.produk.stok + (_jenis == 1 ? _qtyNum : -_qtyNum);

  Future<void> _submit() async {
    if (_qtyNum <= 0) {
      toastError(context, 'Qty harus lebih dari 0');
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.adjustStock(widget.produk.id, _jenis, _qtyNum, keterangan: _ket.text.trim());
      if (mounted) {
        toastOk(context, 'Stok diperbarui');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(
                title: 'Sesuaikan Stok',
                subtitle: widget.produk.nama,
                icon: Icons.swap_vert,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Stok saat ini: ${widget.produk.stok}',
                        style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : ZK.slate500)),
                    const SizedBox(height: 14),
                    const FieldLabel('Jenis'),
                    Row(
                      children: [
                        Expanded(child: _jenisChip('Tambah stok (masuk)', 1, dark)),
                        const SizedBox(width: 8),
                        Expanded(child: _jenisChip('Kurangi stok (keluar)', 2, dark)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel('Jumlah'),
                    TextField(
                        controller: _qty,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        onChanged: (_) => setState(() {}),
                        decoration: sheetInput('0', dark: dark)),
                    const SizedBox(height: 14),
                    const FieldLabel('Keterangan (opsional)'),
                    TextField(
                        controller: _ket,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. stok opname', dark: dark)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: dark ? ZK.primary.withValues(alpha: 0.12) : ZK.brand50,
                          borderRadius: r12),
                      child: Row(
                        children: [
                          Icon(_jenis == 1 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                              size: 18, color: _jenis == 1 ? const Color(0xFF047857) : ZK.rose),
                          const SizedBox(width: 8),
                          Text('Stok akhir: $_stokAkhir',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? Colors.white : ZK.ink)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                            backgroundColor: ZK.primary,
                            shape: const RoundedRectangleBorder(borderRadius: r12)),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Simpan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jenisChip(String label, int jenis, bool dark) {
    final active = _jenis == jenis;
    return GestureDetector(
      onTap: () => setState(() => _jenis = jenis),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
          borderRadius: r12,
          border: Border.all(color: active ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
      ),
    );
  }
}
