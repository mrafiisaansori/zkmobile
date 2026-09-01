import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/pajak_cubit.dart';
import 'sheet_field.dart';

// ===== Tab 2: pajak (PRO) — padanan _PajakTab lama =====
class PajakTab extends StatelessWidget {
  const PajakTab({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => PajakCubit(),
        child: const _PajakTabView(),
      );
}

class _PajakTabView extends StatefulWidget {
  const _PajakTabView();
  @override
  State<_PajakTabView> createState() => _PajakTabViewState();
}

class _PajakTabViewState extends State<_PajakTabView> {
  final _ppnPersen = TextEditingController(text: '0');
  final _servicePersen = TextEditingController(text: '0');
  bool _synced = false;

  @override
  void dispose() {
    _ppnPersen.dispose();
    _servicePersen.dispose();
    super.dispose();
  }

  void _syncControllers(PajakState s) {
    _ppnPersen.text = '${s.ppnPersen}';
    _servicePersen.text = '${s.servicePersen}';
  }

  Future<void> _submit(BuildContext context) async {
    try {
      await context.read<PajakCubit>().save(
            ppnPersen: num.tryParse(_ppnPersen.text) ?? 0,
            servicePersen: num.tryParse(_servicePersen.text) ?? 0,
          );
      if (context.mounted) toastOk(context, 'Pengaturan pajak disimpan');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;

    if (!Session.isPro) {
      return SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_outlined, size: 44, color: ZK.amber700),
                const SizedBox(height: 14),
                Text('Pajak & Service Charge tersedia mulai paket PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 8),
                Text('Atur PPN dan biaya layanan secara terpisah agar perhitungan checkout dan struk tetap konsisten.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: muted)),
              ],
            ),
          ),
        ),
      );
    }

    return BlocConsumer<PajakCubit, PajakState>(
      listener: (context, s) {
        if (s.status == PajakStatus.ready && !_synced) {
          _synced = true;
          _syncControllers(s);
        }
        if (s.status == PajakStatus.error && s.error != null) {
          toastError(context, s.error!);
        }
      },
      builder: (context, s) {
        if (s.status == PajakStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: ZK.primary));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            settingsCard(dark, child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _toggleRow('Aktifkan PPN', s.ppnOn,
                      (v) => context.read<PajakCubit>().setPpnOn(v), dark),
                  if (s.ppnOn) ...[
                    const SizedBox(height: 12),
                    const FieldLabel('Persentase PPN (%)'),
                    TextField(
                        controller: _ppnPersen,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: fg),
                        decoration: sheetInput('0', dark: dark)),
                  ],
                  const SizedBox(height: 16),
                  _toggleRow('Aktifkan Service Charge', s.serviceOn,
                      (v) => context.read<PajakCubit>().setServiceOn(v), dark),
                  if (s.serviceOn) ...[
                    const SizedBox(height: 12),
                    const FieldLabel('Persentase Service Charge (%)'),
                    TextField(
                        controller: _servicePersen,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: fg),
                        decoration: sheetInput('0', dark: dark)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: s.saving ? null : () => _submit(context),
                      style: FilledButton.styleFrom(
                          backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                      child: s.saving
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged, bool dark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dark ? ZK.bgDark : ZK.background,
          borderRadius: r12,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.slate600)),
            ),
            Switch(value: value, onChanged: onChanged, activeThumbColor: ZK.primary),
          ],
        ),
      );
}
