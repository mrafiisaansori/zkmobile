import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/sheet_common.dart';
import '../data/stok_repository.dart';

// Padanan _SesuaikanSheet di lib/admin_stok_page.dart lama.
Future<bool?> showStokAdjustSheet(BuildContext context, Produk produk) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => FormSubmitCubit<bool>(),
      child: StokAdjustSheet(produk: produk),
    ),
  );
}

class StokAdjustSheet extends StatefulWidget {
  final Produk produk;
  const StokAdjustSheet({super.key, required this.produk});
  @override
  State<StokAdjustSheet> createState() => _StokAdjustSheetState();
}

class _StokAdjustSheetState extends State<StokAdjustSheet> {
  final _repo = StokRepository();
  final _qty = TextEditingController();
  final _ket = TextEditingController();
  int _jenis = 1; // 1 = masuk (tambah), 2 = keluar (kurangi)

  @override
  void dispose() {
    _qty.dispose();
    _ket.dispose();
    super.dispose();
  }

  int get _qtyNum => int.tryParse(_qty.text) ?? 0;
  int get _stokAkhir => widget.produk.stok + (_jenis == 1 ? _qtyNum : -_qtyNum);

  void _submit() {
    if (_qtyNum <= 0) {
      toastError(context, 'Qty harus lebih dari 0');
      return;
    }
    context.read<FormSubmitCubit<bool>>().submit(() async {
      await _repo.adjustStock(widget.produk.id, _jenis, _qtyNum, keterangan: _ket.text.trim());
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<FormSubmitCubit<bool>, FormSubmitState<bool>>(
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          toastOk(context, 'Stok diperbarui');
          Navigator.pop(context, true);
        } else if (state.status == FormStatus.error && state.error != null) {
          toastError(context, state.error!);
        }
      },
      child: Padding(
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
                                size: 18, color: _jenis == 1 ? okTone(dark) : ZK.rose),
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
                      BlocBuilder<FormSubmitCubit<bool>, FormSubmitState<bool>>(
                        builder: (context, state) => SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: state.status == FormStatus.submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                                backgroundColor: ZK.primary,
                                shape: const RoundedRectangleBorder(borderRadius: r12)),
                            child: state.status == FormStatus.submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
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
