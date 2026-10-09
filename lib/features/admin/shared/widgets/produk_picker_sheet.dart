import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import 'sheet_common.dart';

// Bottom sheet cari & pilih 1 produk — dipakai form Pembelian & Retur untuk
// mengisi baris item (padanan lib/admin_produk_picker.dart lama, `pickProduk`).
Future<Produk?> pickProduk(BuildContext context) => showModalBottomSheet<Produk>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProdukPickerSheet(),
    );

class ProdukPickerSheet extends StatefulWidget {
  const ProdukPickerSheet({super.key});
  @override
  State<ProdukPickerSheet> createState() => _ProdukPickerSheetState();
}

class _ProdukPickerSheetState extends State<ProdukPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Produk> _data = [];
  bool _loading = true;

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
      final r = apiList(await apiGet('/produk', {
        'search': _search.text.isEmpty ? null : _search.text,
        'category_id': 'all',
        'page': 1,
        'limit': 30,
      }), Produk.fromJson);
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: sheetBox(dark),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SheetHeader(
                title: 'Pilih Produk', subtitle: 'Cari nama atau barcode', icon: Icons.inventory_2_outlined),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onSearch,
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                decoration: sheetInput('Cari produk...', dark: dark).copyWith(
                    prefixIcon: Icon(Icons.search, size: 20, color: dark ? Colors.white60 : ZK.slate400)),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                  : _data.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Produk tidak ditemukan',
                          description: 'Coba kata kunci lain.')
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _data.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: dark ? ZK.lineDark : ZK.line),
                          itemBuilder: (_, i) {
                            final p = _data[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ProductThumb(url: p.foto, size: 40),
                              title: Text(p.nama,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: dark ? Colors.white : ZK.ink)),
                              subtitle: Text('${rupiah(p.hargaJual)} · Stok ${p.stok}',
                                  style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
