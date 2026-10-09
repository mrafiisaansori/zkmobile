import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/cart_cubit.dart';
import '../../../shared/widgets/sheet_common.dart';

// ===== Form open bill (simpan / ubah data bill) =====
class BillFormSheet extends StatefulWidget {
  final String customer, table, note;
  const BillFormSheet({super.key, this.customer = '', this.table = '', this.note = ''});
  @override
  State<BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<BillFormSheet> {
  late final _c = TextEditingController(text: widget.customer);
  late final _t = TextEditingController(text: widget.table);
  late final _n = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _c.dispose();
    _t.dispose();
    _n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = context.watch<CartCubit>().state.count;
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
                  title: widget.customer.isEmpty ? 'Simpan sebagai Open Bill' : 'Ubah data bill',
                  subtitle: '$count item akan disimpan',
                  icon: Icons.assignment_outlined),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('Nama pelanggan / nama bill'),
                    TextField(
                        controller: _c,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. Budi / Take away', dark: dark)),
                    const SizedBox(height: 14),
                    const FieldLabel('Nomor meja (opsional)'),
                    TextField(
                        controller: _t,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. 04', dark: dark)),
                    const SizedBox(height: 14),
                    const FieldLabel('Catatan (opsional)'),
                    TextField(
                        controller: _n,
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('mis. es sedikit, tanpa gula', dark: dark)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration:
                          BoxDecoration(color: dark ? ZK.bgDark : ZK.slate50, borderRadius: r12),
                      child: Text('Stok belum dipotong sampai bill dibayar.',
                          style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, {
                          'customer': _c.text.trim(),
                          'table': _t.text.trim(),
                          'note': _n.text.trim(),
                        }),
                        style: FilledButton.styleFrom(
                            backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                        child: const Text('Simpan Bill',
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
