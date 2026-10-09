import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/sheet_common.dart';
import '../data/voucher_repository.dart';

// Padanan _VoucherFormSheet di lib/admin_voucher_page.dart lama. Submit
// create/update dilakukan di sini lewat FormSubmitCubit<Voucher>, lalu sheet
// pop(true) supaya AdminVoucherPage tinggal refresh ListCubit-nya.
Future<bool?> showVoucherFormSheet(BuildContext context, {Voucher? initial}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => FormSubmitCubit<Voucher>(),
      child: VoucherFormSheet(initial: initial),
    ),
  );
}

class VoucherFormSheet extends StatefulWidget {
  final Voucher? initial;
  const VoucherFormSheet({super.key, this.initial});
  @override
  State<VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<VoucherFormSheet> {
  final _repo = VoucherRepository();
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
    final data = {
      'kode': _kode.text.trim().toUpperCase(),
      'tipe': _tipe,
      'nilai': int.tryParse(_nilai.text) ?? 0,
      'min_transaksi': int.tryParse(_min.text) ?? 0,
      'valid_from': _validFrom,
      'valid_until': _validUntil,
      'is_active': _aktif,
    };
    final item = widget.initial;
    context.read<FormSubmitCubit<Voucher>>().submit(
        () => item == null ? _repo.create(data) : _repo.update(item.id, data));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<FormSubmitCubit<Voucher>, FormSubmitState<Voucher>>(
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          toastOk(context, widget.initial == null ? 'Voucher dibuat' : 'Voucher diperbarui');
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
                        BlocBuilder<FormSubmitCubit<Voucher>, FormSubmitState<Voucher>>(
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
                ),
              ],
            ),
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
