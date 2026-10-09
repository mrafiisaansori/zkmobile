import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/cart_cubit.dart';
import '../models/cart_item.dart';
import '../models/tagihan.dart';
import 'sheet_common.dart';
import 'success_sheet.dart';

// ===== Split bill (padanan components/pos/SplitBillModal.tsx) =====
// Setiap qty dipecah jadi satu "chip" yang bisa dipindah antar orang.
class _Unit {
  final String id, lineId, label;
  final int? detailId;
  final int unitPrice;
  final String? modifierText;
  final CartItem source;
  int person;
  _Unit(this.id, this.lineId, this.label, this.unitPrice, this.person, this.source, this.detailId,
      this.modifierText);
}

class SplitPayload {
  final List<CartItem> items; // baris untuk checkout biasa
  final Map<String, int> perLine; // lineId keranjang -> qty dibayar
  final Map<int, int> perDetail; // id_open_bill_detail -> qty (mode bill)
  final JenisBayar metode;
  final int bayar;
  final String payerName, keterangan;
  SplitPayload(
      this.items, this.perLine, this.perDetail, this.metode, this.bayar, this.payerName, this.keterangan);
}

class SplitBillSheet extends StatefulWidget {
  final List<JenisBayar> jenisBayar;
  final TaxSetting? tax;
  final Qris? qris;
  final bool isPro;
  final Future<CheckoutResult> Function(SplitPayload) onPay;
  const SplitBillSheet({
    super.key,
    required this.jenisBayar,
    required this.tax,
    required this.qris,
    required this.isPro,
    required this.onPay,
  });
  @override
  State<SplitBillSheet> createState() => _SplitBillSheetState();
}

class _SplitBillSheetState extends State<SplitBillSheet> {
  // Snapshot isi keranjang saat sheet dibuka — alokasi per-orang di sini
  // murni state ephemeral lokal, sama seperti kode lama (Cart.i dibaca
  // sekali di _build(), bukan didengarkan terus lewat listener).
  late final List<CartItem> _cartItems = context.read<CartCubit>().state.items;
  int _orang = 2;
  List<_Unit> _units = [];
  int? _aktif;
  late JenisBayar _metode = widget.jenisBayar.first;
  final _bayar = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void dispose() {
    _bayar.dispose();
    super.dispose();
  }

  // Sebar unit bergiliran ke tiap orang (round-robin), sama seperti buildUnits di web.
  void _build() {
    final list = <_Unit>[];
    for (final it in _cartItems) {
      for (var n = 1; n <= it.qty; n++) {
        list.add(_Unit(
          '${it.lineId}-$n',
          it.lineId,
          it.qty > 1 ? '${it.produk.nama} #$n' : it.produk.nama,
          it.unit,
          (list.length % _orang) + 1,
          it,
          it.openBillDetailId,
          it.modifierText,
        ));
      }
    }
    setState(() {
      _units = list;
      _aktif = null;
    });
  }

  void _setOrang(int n) {
    if (n < 1 || n > 12) return;
    setState(() {
      _orang = n;
      for (var i = 0; i < _units.length; i++) {
        if (_units[i].person > n) _units[i].person = (i % n) + 1;
      }
      if (_aktif != null && _aktif! > n) _aktif = null;
    });
  }

  // Tap chip = pindah ke orang berikutnya (mekanik yang sama dengan moveChip di web).
  void _move(_Unit u) => setState(() => u.person = u.person >= _orang ? 1 : u.person + 1);

  List<_Unit> _milik(int person) => _units.where((u) => u.person == person).toList();

  Tagihan _tagihan(List<_Unit> units) {
    final items = <CartItem>[];
    final grouped = <String, int>{};
    for (final u in units) {
      grouped[u.lineId] = (grouped[u.lineId] ?? 0) + 1;
    }
    for (final e in grouped.entries) {
      final src = _units.firstWhere((u) => u.lineId == e.key).source;
      items.add(CartItem(src.produk, e.value, modifiers: src.modifiers, openBillDetailId: src.openBillDetailId));
    }
    return Tagihan.hitung(items: items, tax: widget.tax, isPro: widget.isPro);
  }

  Future<void> _bayarOrang() async {
    final person = _aktif;
    if (person == null) return;
    final units = _milik(person);
    if (units.isEmpty) {
      toastError(context, 'Orang $person belum kebagian item');
      return;
    }
    final t = _tagihan(units);
    final bayar = _metode.isTunai ? (parseRupiah(_bayar.text)) : t.total;
    if (bayar < t.total) {
      toastError(context, 'Nominal bayar kurang dari total');
      return;
    }

    // Kelompokkan unit -> baris keranjang & detail bill.
    final perLine = <String, int>{};
    final perDetail = <int, int>{};
    for (final u in units) {
      perLine[u.lineId] = (perLine[u.lineId] ?? 0) + 1;
      if (u.detailId != null) {
        perDetail[u.detailId!] = (perDetail[u.detailId!] ?? 0) + 1;
      }
    }
    // Baris untuk checkout; pemanggil memakai perLine untuk mengurangi keranjang.
    final items = [
      for (final e in perLine.entries)
        () {
          final src = _units.firstWhere((u) => u.lineId == e.key).source;
          return CartItem(src.produk, e.value,
              modifiers: src.modifiers, openBillDetailId: src.openBillDetailId, stok: src.stok);
        }()
    ];

    setState(() => _loading = true);
    try {
      final res = await widget.onPay(SplitPayload(
        items,
        perLine,
        perDetail,
        _metode,
        bayar,
        'Orang $person',
        'Split Bill - Orang $person',
      ));
      if (!mounted) return;
      _bayar.clear();
      // Buang unit yang sudah dibayar; sisanya masih bisa dibayar orang lain.
      setState(() {
        _units.removeWhere((u) => u.person == person);
        _aktif = null;
      });
      if (_units.isEmpty && mounted) Navigator.pop(context);
      if (!mounted) return;
      playSuccessSound();
      toastOk(context, 'Pembayaran $person berhasil diselesaikan');
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SuccessSheet(result: res, metode: _metode.nama, items: items, judul: 'Split bill dibayar'),
      );
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final t = _aktif == null ? _tagihan(_units) : _tagihan(_milik(_aktif!));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: sheetBox(dark),
        child: Column(
          children: [
            const SheetHeader(title: 'Split Bill', subtitle: 'Bagi item lalu bayar per orang', icon: Icons.call_split),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Jumlah orang',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: dark ? Colors.white70 : const Color(0xFF334155))),
                  const Spacer(),
                  QtyStepper(qty: _orang, onMinus: () => _setOrang(_orang - 1), onPlus: () => _setOrang(_orang + 1)),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _build, child: const Text('Bagi rata')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  Text('Ketuk item untuk memindahkannya ke orang lain.',
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                  const SizedBox(height: 10),
                  for (var p = 1; p <= _orang; p++) _kartuOrang(p, dark),
                ],
              ),
            ),
            _footer(t, dark),
          ],
        ),
      ),
    );
  }

  Widget _kartuOrang(int person, bool dark) {
    final units = _milik(person);
    final t = _tagihan(units);
    final aktif = _aktif == person;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: aktif ? (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50) : (dark ? ZK.cardDark : Colors.white),
        borderRadius: r14,
        border: Border.all(color: aktif ? ZK.primary : (dark ? ZK.lineDark : ZK.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 26,
                width: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: ZK.primary, shape: BoxShape.circle),
                child: Text('$person',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text('Orang $person',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
              const Spacer(),
              Text(rupiah(t.total),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: dark ? Colors.white : ZK.slate900)),
            ],
          ),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Belum ada item',
                  style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
            )
          else ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final u in units)
                  InkWell(
                    onTap: () => _move(u),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: dark ? ZK.bgDark : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: dark ? ZK.lineDark : ZK.brand200),
                      ),
                      child: Text('${u.label} · ${rupiah(u.unitPrice)}',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: dark ? Colors.white : const Color(0xFF1E293B))),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: units.isEmpty ? null : () => setState(() => _aktif = aktif ? null : person),
              style: OutlinedButton.styleFrom(
                  foregroundColor: aktif ? ZK.primary : (dark ? Colors.white70 : ZK.muted),
                  side: BorderSide(color: aktif ? ZK.primary : (dark ? ZK.lineDark : ZK.line)),
                  shape: const RoundedRectangleBorder(borderRadius: r12)),
              child: Text(aktif ? 'Dipilih untuk dibayar' : 'Bayar orang ini',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(Tagihan t, bool dark) => Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          border: Border(top: BorderSide(color: dark ? ZK.lineDark : ZK.brand100)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_aktif == null ? 'Total semua' : 'Tagihan orang $_aktif',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dark ? Colors.white70 : ZK.muted)),
                Text(rupiah(t.total),
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : ZK.ink)),
              ],
            ),
            if (_aktif != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final j in widget.jenisBayar)
                    InkWell(
                      onTap: () => setState(() => _metode = j),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _metode.id == j.id ? ZK.primary : (dark ? ZK.bgDark : Colors.white),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _metode.id == j.id ? ZK.primary : (dark ? ZK.lineDark : ZK.brand200)),
                        ),
                        child: Text(j.nama,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _metode.id == j.id ? Colors.white : (dark ? Colors.white70 : ZK.muted))),
                      ),
                    ),
                ],
              ),
              if (_metode.isTunai) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _bayar,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  inputFormatters: [RupiahInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: dark ? Colors.white : ZK.ink),
                  decoration: sheetInput('Uang diterima', prefix: 'Rp  ', dark: dark),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _bayarOrang,
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Bayar ${rupiah(t.total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ],
        ),
      );
}
