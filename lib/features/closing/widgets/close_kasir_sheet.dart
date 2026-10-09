import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/closing_repository.dart';
import '../../../shared/widgets/sheet_common.dart';

// Padanan _CloseKasirSheet lama — preview selisih + input uang fisik untuk
// menutup sesi kasir.
class CloseKasirSheet extends StatefulWidget {
  final int shiftId;
  final Map<String, dynamic> preview;
  const CloseKasirSheet({super.key, required this.shiftId, required this.preview});
  @override
  State<CloseKasirSheet> createState() => _CloseKasirSheetState();
}

class _CloseKasirSheetState extends State<CloseKasirSheet> {
  final _repo = ClosingRepository();
  final _actual = TextEditingController();
  final _catatan = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _actual.dispose();
    _catatan.dispose();
    super.dispose();
  }

  int get _expected => ((widget.preview['expected_cash'] as num?) ?? 0).toInt();
  int get _actualNum => parseRupiah(_actual.text);
  int get _selisih => _actualNum - _expected;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final res =
          await _repo.close(widget.shiftId, _actualNum, catatan: _catatan.text.trim());
      if (!mounted) return;
      Navigator.pop(context, res);
      toastOk(context, 'Kasir berhasil ditutup');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.preview;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(
                    title: 'Tutup Kasir',
                    subtitle: 'Hitung & cocokkan uang tunai di laci',
                    icon: Icons.lock_outline),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50,
                            borderRadius: r14),
                        child: Column(
                          children: [
                            _row('Modal awal', rupiah(((p['modal_awal'] as num?) ?? 0)), dark),
                            _row('Penjualan tunai',
                                '+ ${rupiah(((p['cash_sales'] as num?) ?? 0))}', dark),
                            _row('Kas masuk', '+ ${rupiah(((p['mutasi_in'] as num?) ?? 0))}',
                                dark),
                            _row('Kas keluar', '- ${rupiah(((p['mutasi_out'] as num?) ?? 0))}',
                                dark),
                            Divider(height: 16, color: dark ? ZK.lineDark : ZK.brand200),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Uang tunai seharusnya',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: dark ? Colors.white : ZK.ink)),
                                Text(rupiah(_expected),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: ZK.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Uang tunai hasil hitung di laci'),
                      TextField(
                        controller: _actual,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        autofocus: true,
                        inputFormatters: [RupiahInputFormatter()],
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : ZK.slate900),
                        decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                      ),
                      if (_actual.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                              color: _selisih == 0
                                  ? softBg(ZK.success, ZK.successBg, dark)
                                  : (_selisih < 0 ? softBg(ZK.rose, ZK.rose50, dark) : softBg(ZK.amber700, ZK.amber50, dark)),
                              borderRadius: r12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  _selisih == 0
                                      ? 'Cocok / pas'
                                      : (_selisih < 0 ? 'Kurang' : 'Lebih'),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selisih == 0
                                          ? okTone(dark)
                                          : (_selisih < 0 ? ZK.rose : ZK.amber700))),
                              Text(rupiah(_selisih.abs()),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _selisih == 0
                                          ? okTone(dark)
                                          : (_selisih < 0 ? ZK.rose : ZK.amber700))),
                            ],
                          ),
                        ),
                      ],
                      if (((p['non_cash_sales'] as num?) ?? 0) > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                            'Penjualan non-tunai (${rupiah(((p['non_cash_sales'] as num?) ?? 0))}) tidak dihitung di sini karena tidak ada uang fisik di laci.',
                            style: const TextStyle(fontSize: 11, color: ZK.slate500)),
                      ],
                      const SizedBox(height: 14),
                      const FieldLabel('Catatan (opsional)'),
                      TextField(
                          controller: _catatan,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. Selisih karena kembalian', dark: dark)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Tutup & Simpan',
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
      ),
    );
  }

  Widget _row(String l, String v, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : ZK.muted)),
            Text(v,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : ZK.slate900)),
          ],
        ),
      );
}
