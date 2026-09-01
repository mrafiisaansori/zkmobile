import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/supplier/page.tsx — CRUD supplier.
class AdminSupplierPage extends StatefulWidget {
  const AdminSupplierPage({super.key});
  @override
  State<AdminSupplierPage> createState() => _AdminSupplierPageState();
}

class _AdminSupplierPageState extends State<AdminSupplierPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Supplier> _data = [];
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
      final r = await Api.suppliers(search: _search.text);
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

  Future<void> _openForm({Supplier? item}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await Api.createSupplier(result);
        if (mounted) toastOk(context, 'Supplier ditambahkan');
      } else {
        await Api.updateSupplier(item.id, result);
        if (mounted) toastOk(context, 'Supplier diperbarui');
      }
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Supplier item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus supplier?', message: 'Hapus supplier "${item.nama}"?', danger: true);
    if (!ok) return;
    try {
      await Api.deleteSupplier(item.id);
      if (mounted) toastOk(context, 'Supplier dihapus');
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
                        hintText: 'Cari nama / telepon...',
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
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary,
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : _data.isEmpty
                    ? const EmptyState(
                        icon: Icons.local_shipping_outlined,
                        title: 'Belum ada supplier',
                        description: 'Tambah data supplier untuk pembelian barang.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final s = _data[i];
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
                                        color:
                                            dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.local_shipping_outlined,
                                        color: ZK.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.nama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                        const SizedBox(height: 2),
                                        if (s.noTelp != null || s.email != null || s.alamat != null)
                                          Text(
                                              [
                                                if (s.noTelp != null) s.noTelp!,
                                                if (s.email != null) s.email!,
                                                if (s.alamat != null) s.alamat!,
                                              ].join(' · '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12, color: muted)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: s.status == 0
                                                  ? ZK.rose50
                                                  : (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50),
                                              borderRadius: BorderRadius.circular(999)),
                                          child: Text(s.status == 0 ? 'Nonaktif' : 'Aktif',
                                              style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: s.status == 0
                                                      ? ZK.rose
                                                      : (dark ? Colors.white : ZK.brand700))),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openForm(item: s),
                                          icon: Icon(Icons.edit_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _hapus(s),
                                          icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
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

class _SupplierFormSheet extends StatefulWidget {
  final Supplier? initial;
  const _SupplierFormSheet({this.initial});
  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  late final _nama = TextEditingController(text: widget.initial?.nama ?? '');
  late final _telp = TextEditingController(text: widget.initial?.noTelp ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _alamat = TextEditingController(text: widget.initial?.alamat ?? '');
  late final _catatan = TextEditingController(text: widget.initial?.catatan ?? '');
  late bool _aktif = (widget.initial?.status ?? 1) == 1;

  @override
  void dispose() {
    _nama.dispose();
    _telp.dispose();
    _email.dispose();
    _alamat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) {
      toastError(context, 'Nama supplier wajib diisi');
      return;
    }
    Navigator.pop(context, {
      'nama': _nama.text.trim(),
      'no_telp': _telp.text.trim(),
      'email': _email.text.trim(),
      'alamat': _alamat.text.trim(),
      'catatan': _catatan.text.trim(),
      'status': _aktif ? 1 : 0,
    });
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
                title: widget.initial == null ? 'Tambah Supplier' : 'Ubah Supplier',
                subtitle: 'Data supplier barang',
                icon: Icons.local_shipping_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Nama supplier'),
                      TextField(
                          controller: _nama,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. PT Sumber Rejeki', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('No. Telepon / WhatsApp'),
                      TextField(
                          controller: _telp,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('081234567890', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Email (opsional)'),
                      TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. supplier@email.com', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Alamat'),
                      TextField(
                          controller: _alamat,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Alamat supplier', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Catatan (opsional)'),
                      TextField(
                          controller: _catatan,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Catatan tambahan', dark: dark)),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _aktif,
                        onChanged: (v) => setState(() => _aktif = v),
                        activeThumbColor: ZK.primary,
                        title: Text('Aktif',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : ZK.ink)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                          child: const Text('Simpan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
