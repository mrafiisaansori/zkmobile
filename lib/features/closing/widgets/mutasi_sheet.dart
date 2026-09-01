import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/closing_repository.dart';
import 'sheet_common.dart';

// Padanan _MutasiSheet lama — catat kas keluar/masuk di luar penjualan
// (mis. ambil uang / tambah modal).
class MutasiSheet extends StatefulWidget {
  final int shiftId;
  const MutasiSheet({super.key, required this.shiftId});
  @override
  State<MutasiSheet> createState() => _MutasiSheetState();
}

class _MutasiSheetState extends State<MutasiSheet> {
  final _repo = ClosingRepository();
  String _tipe = 'OUT';
  final _nominal = TextEditingController();
  final _ket = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nominal.dispose();
    _ket.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final n = parseRupiah(_nominal.text);
    if (n <= 0) {
      toastError(context, 'Nominal harus lebih dari 0');
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.mutasi(widget.shiftId, _tipe, n, keterangan: _ket.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
      toastOk(context, _tipe == 'OUT' ? 'Kas keluar dicatat' : 'Kas masuk dicatat');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                const SheetHeader(
                    title: 'Catat Kas Keluar / Masuk',
                    subtitle: 'Di luar penjualan, mis. ambil uang / tambah modal',
                    icon: Icons.swap_vert),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _tipeBtn(
                                'OUT', 'Kas Keluar', Icons.arrow_upward, ZK.rose, dark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tipeBtn('IN', 'Kas Masuk', Icons.arrow_downward,
                                const Color(0xFF10B981), dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Nominal'),
                      TextField(
                        controller: _nominal,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        inputFormatters: [RupiahInputFormatter()],
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                      ),
                      const SizedBox(height: 14),
                      const FieldLabel('Keterangan (opsional)'),
                      TextField(
                          controller: _ket,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. Beli galon air', dark: dark)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
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

  Widget _tipeBtn(String tipe, String label, IconData icon, Color tone, bool dark) {
    final aktif = _tipe == tipe;
    return InkWell(
      onTap: () => setState(() => _tipe = tipe),
      borderRadius: r12,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: aktif ? tone.withValues(alpha: 0.1) : (dark ? ZK.cardDark : Colors.white),
          borderRadius: r12,
          border: Border.all(
              color: aktif ? tone : (dark ? ZK.lineDark : ZK.line), width: aktif ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: aktif ? tone : (dark ? Colors.white54 : ZK.slate500)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: aktif ? tone : (dark ? Colors.white70 : ZK.slate500))),
          ],
        ),
      ),
    );
  }
}
