import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/pos_repository.dart';
import 'sheet_common.dart';

// ===== Buka sesi kasir =====
// Dipakai berdiri sendiri (mis. DashboardPage) maupun dari dalam POS, jadi
// TIDAK menerima callback/cubit wajib dari pemanggil — panggil PosRepository
// sendiri persis seperti Api.openShift() di kode lama.
class BukaSesiSheet extends StatefulWidget {
  const BukaSesiSheet({super.key});
  @override
  State<BukaSesiSheet> createState() => _BukaSesiSheetState();
}

class _BukaSesiSheetState extends State<BukaSesiSheet> {
  final _repo = PosRepository();
  final _modal = TextEditingController(text: '0');
  final _catatan = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _modal.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _repo.openShift(parseRupiah(_modal.text), catatan: _catatan.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
      toastOk(context, 'Sesi kasir dibuka');
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
                  title: 'Buka Sesi Kasir',
                  subtitle: 'Transaksi baru bisa dimulai setelah sesi dibuka',
                  icon: Icons.lock_open),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('Modal awal laci'),
                    TextField(
                      controller: _modal,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      inputFormatters: [RupiahInputFormatter()],
                      style: TextStyle(color: dark ? Colors.white : ZK.ink),
                      decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel('Catatan (opsional)'),
                    TextField(
                        controller: _catatan,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. shift pagi', dark: dark)),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                            backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Buka Sesi',
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
}
