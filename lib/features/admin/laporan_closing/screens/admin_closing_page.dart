import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/laporan_closing_cubit.dart';
import '../data/laporan_closing_repository.dart';

// Padanan src/app/admin/laporan/closing/page.tsx — rekap sesi kas SELURUH
// kasir per hari beserta selisihnya (beda dari features/closing/ yang
// dipakai KASIR untuk buka/tutup kas sesi miliknya sendiri).
class AdminClosingPage extends StatelessWidget {
  const AdminClosingPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => LaporanClosingCubit(LaporanClosingRepository()),
        child: const _AdminClosingView(),
      );
}

class _AdminClosingView extends StatelessWidget {
  const _AdminClosingView();

  String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

  String _fmtJam(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.tryParse(iso);
    if (d == null) return '-';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _selisihText(int? v) {
    if (v == null) return '-';
    if (v == 0) return 'Pas';
    return v < 0 ? 'Kurang ${rupiah(-v)}' : 'Lebih ${rupiah(v)}';
  }

  Color _selisihColor(int? v, bool dark) {
    if (v == null) return dark ? Colors.white54 : ZK.slate400;
    if (v == 0) return dark ? Colors.greenAccent : const Color(0xFF047857);
    return v < 0 ? ZK.rose : ZK.amber700;
  }

  Future<void> _pickTanggal(BuildContext context, DateTime current) async {
    final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDate: current,
        locale: const Locale('id'));
    if (d == null || !context.mounted) return;
    context.read<LaporanClosingCubit>().setTanggal(d);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate500;
    return BlocConsumer<LaporanClosingCubit, LaporanClosingState>(
      listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
      listener: (context, state) => toastError(context, state.error!),
      builder: (context, state) {
        final r = state.report;
        final selisihTotal = r?.totalSelisihCash ?? 0;
        return SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: OutlinedButton.icon(
                  onPressed: () => _pickTanggal(context, state.tanggal),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_iso(state.tanggal), style: const TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: dark ? ZK.cardDark : Colors.white,
                    foregroundColor: dark ? Colors.white : ZK.primary,
                    side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    minimumSize: const Size(double.infinity, 46),
                    shape: const RoundedRectangleBorder(borderRadius: r12),
                  ),
                ),
              ),
              Expanded(
                child: state.loading
                    ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: () => context.read<LaporanClosingCubit>().load(),
                        child: Builder(builder: (context) {
                          // Tablet: Row of Expanded (tinggi ikut konten), bukan
                          // GridView beraspek-rasio tetap — di layar lebar itu
                          // bikin sel jauh lebih tinggi dari kontennya.
                          final cards = [
                            _statCard('Total Penjualan Tunai', rupiah(r?.totalCashSales ?? 0),
                                Icons.payments_outlined, const Color(0xFF047857), dark),
                            _statCard('Total Non-Tunai', rupiah(r?.totalNonCashSales ?? 0),
                                Icons.credit_card_outlined, ZK.primary, dark),
                            _statCard('Total Omzet', rupiah(r?.totalOmzet ?? 0),
                                Icons.account_balance_wallet_outlined, ZK.primary, dark),
                            _statCard('Selisih Kas Hari Ini', _selisihText(selisihTotal),
                                Icons.balance_outlined, _selisihColor(selisihTotal, dark), dark),
                          ];
                          final statRow = isTablet(context)
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (var i = 0; i < cards.length; i++) ...[
                                        if (i > 0) const SizedBox(width: 10),
                                        Expanded(child: cards[i]),
                                      ],
                                    ],
                                  ),
                                )
                              : GridView.count(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.6,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: cards,
                                );
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              statRow,
                              const SizedBox(height: 14),
                              Text('${r?.jumlahShift ?? 0} sesi kasir pada tanggal ini.',
                                  style: TextStyle(fontSize: 13, color: muted)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: dark ? ZK.cardDark : ZK.background, borderRadius: r12),
                                child: Text(
                                    'Uang Seharusnya = Modal Awal + Penjualan Tunai. Selisih = Uang Dihitung − Uang Seharusnya.',
                                    style: TextStyle(fontSize: 11, color: muted)),
                              ),
                              const SizedBox(height: 12),
                              if ((r?.shift ?? []).isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text('Belum ada sesi kas pada tanggal ini',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: muted)),
                                )
                              else
                                for (final s in r!.shift) _shiftCard(s, dark, fg, muted),
                            ],
                          );
                        }),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color tone, bool dark) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: tone),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: dark ? Colors.white60 : ZK.slate500)),
          ],
        ),
      );

  Widget _shiftCard(DailyReportRow s, bool dark, Color fg, Color muted) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.kasir ?? '-',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                      Text(
                          '${s.station ?? 'Tanpa laci'} · ${_fmtJam(s.bukaAt)}–${s.status == 'OPEN' ? 'kini' : _fmtJam(s.tutupAt)}',
                          style: TextStyle(fontSize: 11.5, color: muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: s.status == 'OPEN'
                          ? ZK.amber50
                          : (dark ? ZK.primary.withValues(alpha: 0.16) : const Color(0xFFECFDF5)),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(s.status == 'OPEN' ? 'BUKA' : 'SELESAI',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: s.status == 'OPEN'
                              ? ZK.amber700
                              : (dark ? Colors.greenAccent : const Color(0xFF047857)))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _kv('Modal Awal', rupiah(s.modalAwal), fg, muted)),
                Expanded(child: _kv('Tunai', rupiah(s.cashSales), fg, muted)),
                Expanded(child: _kv('Non-Tunai', s.nonCashSales > 0 ? rupiah(s.nonCashSales) : '—', fg, muted)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _kv('Seharusnya', rupiah(s.expectedCash), fg, muted)),
                Expanded(
                    child: _kv(
                        'Dihitung', s.actualCash == null ? '—' : rupiah(s.actualCash!), fg, muted)),
                Expanded(
                  child: _kv('Selisih', _selisihText(s.selisihCash), fg, muted,
                      valueColor: _selisihColor(s.selisihCash, dark)),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _kv(String label, String value, Color fg, Color muted, {Color? valueColor}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: muted)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor ?? fg)),
        ],
      );
}
