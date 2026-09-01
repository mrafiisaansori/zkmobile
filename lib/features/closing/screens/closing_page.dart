import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../../pos/widgets/buka_sesi_sheet.dart';
import '../cubit/closing_cubit.dart';
import '../widgets/close_kasir_sheet.dart';
import '../widgets/mutasi_sheet.dart';

// Padanan src/app/kasir/closing/page.tsx — buka/tutup sesi kasir, catat kas
// masuk/keluar, dan tutup kasir dengan hitung selisih uang tunai.
class ClosingPage extends StatelessWidget {
  const ClosingPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ClosingCubit()..load(),
        child: const _ClosingView(),
      );
}

class _ClosingView extends StatelessWidget {
  const _ClosingView();

  Future<void> _bukaKasir(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BukaSesiSheet(),
    );
    if (ok == true && context.mounted) {
      context.read<ClosingCubit>().afterBukaKasir();
    }
  }

  Future<void> _catatMutasi(BuildContext context, int? shiftId) async {
    if (shiftId == null) return;
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MutasiSheet(shiftId: shiftId),
    );
    if (done == true && context.mounted) {
      context.read<ClosingCubit>().afterMutasi();
    }
  }

  Future<void> _tutupKasir(BuildContext context, int? shiftId) async {
    if (shiftId == null) return;
    final cubit = context.read<ClosingCubit>();
    try {
      final preview = await cubit.closePreview(shiftId);
      if (!context.mounted) return;
      final closed = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CloseKasirSheet(shiftId: shiftId, preview: preview),
      );
      if (closed != null) cubit.setClosed(closed);
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ClosingCubit, ClosingState>(
        listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
        listener: (context, state) => toastError(context, state.error!),
        builder: (context, state) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final fg = dark ? Colors.white : ZK.ink;
          final muted = dark ? Colors.white70 : ZK.slate500;
          final cardColor = dark ? ZK.cardDark : Colors.white;
          final lineColor = dark ? ZK.lineDark : ZK.line;
          return HeroShell(
            child: SafeArea(
              top: false,
              bottom: false,
              child: state.loading
                  ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                  : RefreshIndicator(
                      color: ZK.primary,
                      onRefresh: () => context.read<ClosingCubit>().load(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          if (state.shift == null && state.result == null)
                            _bukaKasirCard(context, dark, fg, muted, cardColor, lineColor),
                          if (state.result != null)
                            _resultCard(
                                context, state.result!, dark, fg, muted, cardColor, lineColor),
                          if (state.shift != null)
                            ..._shiftAktif(
                                context, state.shift!, dark, fg, muted, cardColor, lineColor),
                        ],
                      ),
                    ),
            ),
          );
        },
      );

  Widget _bukaKasirCard(BuildContext context, bool dark, Color fg, Color muted, Color cardColor,
          Color lineColor) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
            color: cardColor, borderRadius: r14, border: Border.all(color: lineColor)),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                  color: dark ? ZK.primary.withValues(alpha: 0.2) : ZK.brand50,
                  borderRadius: r14),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  size: 30, color: ZK.primary),
            ),
            const SizedBox(height: 14),
            Text('Kasir belum dibuka',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 6),
            Text(
                'Buka kasir dulu sebelum mulai jualan. Semua transaksimu akan tercatat di sesi ini untuk dicocokkan saat tutup.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: muted)),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _bukaKasir(context),
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Buka Kasir',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ],
        ),
      );

  Widget _resultCard(BuildContext context, Map<String, dynamic> r, bool dark, Color fg,
      Color muted, Color cardColor, Color lineColor) {
    final selisih = (r['SELISIH_CASH'] as num?)?.toInt() ?? 0;
    final pas = selisih == 0;
    final kurang = selisih < 0;
    final tone = pas ? const Color(0xFF10B981) : (kurang ? ZK.rose : ZK.amber700);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: r14, border: Border.all(color: lineColor)),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(pas ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 32, color: tone),
          ),
          const SizedBox(height: 12),
          Text('Kasir Ditutup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _miniStat('Seharusnya',
                      rupiah(((r['EXPECTED_CASH'] as num?) ?? 0)), dark, fg)),
              const SizedBox(width: 8),
              Expanded(
                  child: _miniStat(
                      'Dihitung', rupiah(((r['ACTUAL_CASH'] as num?) ?? 0)), dark, fg)),
              const SizedBox(width: 8),
              Expanded(
                  child: _miniStat(pas ? 'Selisih' : (kurang ? 'Kurang' : 'Lebih'),
                      rupiah(selisih.abs()), dark, tone)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _bukaKasir(context),
              icon: const Icon(Icons.lock_open, size: 16),
              label: const Text('Buka Kasir Lagi'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: ZK.primary,
                  side: const BorderSide(color: ZK.brand200),
                  shape: const RoundedRectangleBorder(borderRadius: r12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, bool dark, Color valueColor) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
            color: dark ? ZK.bgDark : ZK.brand50, borderRadius: r12),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: dark ? Colors.white70 : ZK.slate500)),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: valueColor)),
          ],
        ),
      );

  List<Widget> _shiftAktif(BuildContext context, Map<String, dynamic> s, bool dark, Color fg,
      Color muted, Color cardColor, Color lineColor) {
    final pv = (s['preview'] as Map<String, dynamic>?) ?? {};
    final methods = (pv['methods'] as List?) ?? [];
    final mutasiNet = ((pv['mutasi_out'] as num?) ?? 0) - ((pv['mutasi_in'] as num?) ?? 0);
    final shiftId = s['ID'] as int?;
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cardColor, borderRadius: r14, border: Border.all(color: lineColor)),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5), borderRadius: r12),
              child: const Icon(Icons.lock_open, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kasir Sedang Buka',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                  Text(
                      [
                        if (s['kasir'] != null) '${s['kasir']['NAMA']}',
                        if (s['STATION'] != null) '${s['STATION']}',
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Modal Awal', style: TextStyle(fontSize: 11, color: muted)),
                Text(rupiah(((s['MODAL_AWAL'] as num?) ?? 0)),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: ZK.primary)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
              child: _statBox('Penjualan Tunai',
                  rupiah(((pv['cash_sales'] as num?) ?? 0)), Icons.payments_outlined,
                  const Color(0xFF10B981), dark, fg, cardColor, lineColor)),
          const SizedBox(width: 10),
          Expanded(
              child: _statBox('Non-Tunai', rupiah(((pv['non_cash_sales'] as num?) ?? 0)),
                  Icons.credit_card, ZK.primary, dark, fg, cardColor, lineColor)),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
              child: _statBox('Kas Keluar/Masuk', rupiah(mutasiNet), Icons.swap_vert,
                  ZK.amber700, dark, fg, cardColor, lineColor)),
          const SizedBox(width: 10),
          Expanded(
              child: _statBox('Uang Seharusnya', rupiah(((pv['expected_cash'] as num?) ?? 0)),
                  Icons.account_balance_wallet_outlined, ZK.primary, dark, fg, cardColor,
                  lineColor)),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cardColor, borderRadius: r14, border: Border.all(color: lineColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rincian per metode bayar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 2),
            Text('${pv['jumlah_transaksi'] ?? 0} transaksi pada sesi ini.',
                style: TextStyle(fontSize: 12, color: muted)),
            const SizedBox(height: 8),
            if (methods.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: Text('Belum ada transaksi.',
                        style: TextStyle(fontSize: 12, color: muted))),
              )
            else
              for (final m in methods)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                              m['is_cash'] == true
                                  ? Icons.payments_outlined
                                  : Icons.credit_card,
                              size: 16,
                              color: m['is_cash'] == true
                                  ? const Color(0xFF10B981)
                                  : muted),
                          const SizedBox(width: 8),
                          Text('${m['nama']}', style: TextStyle(fontSize: 13, color: fg)),
                        ],
                      ),
                      Text(rupiah(((m['expected'] as num?) ?? 0)),
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                    ],
                  ),
                ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _catatMutasi(context, shiftId),
                icon: const Icon(Icons.swap_vert, size: 17),
                label: const Text('Kas Keluar/Masuk'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: dark ? Colors.white : ZK.primary,
                    side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _tutupKasir(context, shiftId),
                icon: const Icon(Icons.lock_outline, size: 17),
                label: const Text('Tutup Kasir'),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _statBox(String label, String value, IconData icon, Color tone, bool dark,
          Color fg, Color cardColor, Color lineColor) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: cardColor, borderRadius: r14, border: Border.all(color: lineColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 30,
              width: 30,
              decoration:
                  BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: r12),
              child: Icon(icon, size: 16, color: tone),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(fontSize: 11, color: dark ? Colors.white70 : ZK.slate500)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
          ],
        ),
      );
}
