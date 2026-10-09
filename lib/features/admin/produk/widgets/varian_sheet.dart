import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/form_submit_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../data/produk_repository.dart';
import 'sheet_common.dart';

// Assign grup varian ke produk (checkbox list) — padanan modal "Varian" di
// web dan _VarianSheet di admin_produk_page.dart lama. Simpan dibungkus
// FormSubmitCubit<void> supaya statusnya BLoC, bukan setState _saving lokal.
class VarianSheet extends StatefulWidget {
  final Produk produk;
  final ProdukRepository repo;
  const VarianSheet({super.key, required this.produk, required this.repo});
  @override
  State<VarianSheet> createState() => _VarianSheetState();
}

class _VarianSheetState extends State<VarianSheet> {
  final _formCubit = FormSubmitCubit<void>();
  List<ModifierGroup> _all = [];
  List<int> _selected = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _formCubit.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait(
          [widget.repo.modifierGroups(), widget.repo.modifierFor(widget.produk.id)]);
      if (!mounted) return;
      setState(() {
        _all = results[0];
        _selected = results[1].map((g) => g.id).toList();
      });
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simpan() async {
    await _formCubit.submit(
        () => widget.repo.setProductModifierGroups(widget.produk.id, _selected));
    if (!mounted) return;
    if (_formCubit.state.status == FormStatus.success) {
      toastOk(context, 'Varian produk disimpan');
      Navigator.pop(context);
    } else if (_formCubit.state.error != null) {
      toastError(context, _formCubit.state.error!);
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
              SheetHeader(
                title: 'Varian - ${widget.produk.nama}',
                subtitle: 'Pilih grup varian yang berlaku',
                icon: Icons.layers_outlined,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: ZK.primary)),
                )
              else if (_all.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Belum ada grup varian. Buat dulu di menu Varian.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : ZK.slate500)),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final g in _all)
                          CheckboxListTile(
                            value: _selected.contains(g.id),
                            onChanged: (v) => setState(() =>
                                v == true ? _selected.add(g.id) : _selected.remove(g.id)),
                            activeColor: ZK.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.nama,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white : ZK.ink)),
                            subtitle: Text('${g.options.length} opsi',
                                style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : ZK.slate500)),
                          ),
                        const SizedBox(height: 8),
                        BlocBuilder<FormSubmitCubit<void>, FormSubmitState<void>>(
                          bloc: _formCubit,
                          builder: (context, state) => SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: state.status == FormStatus.submitting ? null : _simpan,
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
    );
  }
}
