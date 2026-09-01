import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/voucher/page.tsx — CRUD voucher/promo. Voucher yang
// SUDAH ADA tetap bisa dikelola di semua plan; bikin voucher BARU PRO-only.
class AdminVoucherPage extends StatefulWidget {
  const AdminVoucherPage({super.key});
  @override
  State<AdminVoucherPage> createState() => _AdminVoucherPageState();
}

class _AdminVoucherPageState extends State<AdminVoucherPage> {
  List<Voucher> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.vouchers();
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Voucher? item}) async {
    if (item == null && !Session.isPro) {
      toastError(context, 'Bikin voucher baru hanya tersedia untuk paket PRO/BUSINESS.');
      return;
    }
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await Api.createVoucher(result);
        if (mounted) toastOk(context, 'Voucher dibuat');
      } else {
        await Api.updateVoucher(item.id, result);
        if (mounted) toastOk(context, 'Voucher diperbarui');
      }
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Voucher item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus voucher?', message: 'Hapus voucher "${item.kode}"?', danger: true);
    if (!ok) return;
    try {
      await Api.deleteVoucher(item.id);
      if (mounted) toastOk(context, 'Voucher dihapus');
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
            child: SizedBox(
              height: 46,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Voucher'),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
          if (!Session.isPro)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ZK.amber50, borderRadius: r12),
                child: Text('Bikin voucher baru tersedia mulai paket PRO. Voucher lama tetap bisa dikelola.',
                    style: TextStyle(fontSize: 12, color: ZK.amber700)),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : _data.isEmpty
                    ? const EmptyState(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Belum ada voucher',
                        description: 'Buat kode promo untuk dipakai kasir saat checkout.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final v = _data[i];
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
                                    child: const Icon(Icons.confirmation_number_outlined,
                                        color: ZK.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v.kode,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'monospace',
                                                color: fg)),
                                        const SizedBox(height: 2),
                                        Text(
                                            '${v.persen ? '${v.nilai}%' : rupiah(v.nilai)} · Min. ${rupiah(v.minTransaksi)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: muted)),
                                        Text('Berlaku ${v.validFrom ?? '-'} s/d ${v.validUntil ?? '-'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: muted)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: v.aktif
                                                  ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50)
                                                  : ZK.rose50,
                                              borderRadius: BorderRadius.circular(999)),
                                          child: Text(v.aktif ? 'Aktif' : 'Nonaktif',
                                              style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: v.aktif
                                                      ? (dark ? Colors.white : ZK.brand700)
                                                      : ZK.rose)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openForm(item: v),
                                          icon: Icon(Icons.edit_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _hapus(v),
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

class _VoucherFormSheet extends StatefulWidget {
  final Voucher? initial;
  const _VoucherFormSheet({this.initial});
  @override
  State<_VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<_VoucherFormSheet> {
  late final _kode = TextEditingController(text: widget.initial?.kode ?? '');
  late final _nilai =
      TextEditingController(text: widget.initial != null ? '${widget.initial!.nilai}' : '');
  late final _min =
      TextEditingController(text: widget.initial != null ? '${widget.initial!.minTransaksi}' : '0');
  late String _tipe = widget.initial?.tipe ?? 'NOMINAL';
  late bool _aktif = widget.initial?.aktif ?? true;
  String? _validFrom, _validUntil;

  @override
  void initState() {
    super.initState();
    _validFrom = widget.initial?.validFrom;
    _validUntil = widget.initial?.validUntil;
  }

  @override
  void dispose() {
    _kode.dispose();
    _nilai.dispose();
    _min.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool from) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
      locale: const Locale('id'),
    );
    if (d == null) return;
    final iso = d.toIso8601String().substring(0, 10);
    setState(() => from ? _validFrom = iso : _validUntil = iso);
  }

  void _submit() {
    if (_kode.text.trim().isEmpty) {
      toastError(context, 'Kode voucher wajib diisi');
      return;
    }
    Navigator.pop(context, {
      'kode': _kode.text.trim().toUpperCase(),
      'tipe': _tipe,
      'nilai': int.tryParse(_nilai.text) ?? 0,
      'min_transaksi': int.tryParse(_min.text) ?? 0,
      'valid_from': _validFrom,
      'valid_until': _validUntil,
      'is_active': _aktif,
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
                title: widget.initial == null ? 'Tambah Voucher' : 'Ubah Voucher',
                subtitle: 'Kode diskon untuk checkout',
                icon: Icons.confirmation_number_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Kode voucher'),
                      TextField(
                          controller: _kode,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('DISKON10', dark: dark)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _tipeChip('Nominal (Rp)', 'NOMINAL', dark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tipeChip('Persen (%)', 'PERSEN', dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FieldLabel(_tipe == 'PERSEN' ? 'Nilai (%)' : 'Nilai (Rp)'),
                      TextField(
                          controller: _nilai,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('0', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Minimal transaksi (Rp)'),
                      TextField(
                          controller: _min,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('0', dark: dark)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(true),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: dark ? Colors.white : ZK.ink,
                                  side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                                  shape: const RoundedRectangleBorder(borderRadius: r12)),
                              child: Text(_validFrom ?? 'Berlaku dari'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(false),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: dark ? Colors.white : ZK.ink,
                                  side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                                  shape: const RoundedRectangleBorder(borderRadius: r12)),
                              child: Text(_validUntil ?? 'Sampai'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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

  Widget _tipeChip(String label, String tipe, bool dark) {
    final active = _tipe == tipe;
    return GestureDetector(
      onTap: () => setState(() => _tipe = tipe),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
          borderRadius: r12,
          border: Border.all(color: active ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
      ),
    );
  }
}
