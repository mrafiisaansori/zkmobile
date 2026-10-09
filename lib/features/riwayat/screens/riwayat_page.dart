import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/riwayat_cubit.dart';
import 'riwayat_detail_page.dart';

// Padanan src/app/kasir/riwayat/page.tsx (daftar transaksi kasir).
class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => RiwayatCubit()..load(),
        child: const _RiwayatView(),
      );
}

class _RiwayatView extends StatefulWidget {
  const _RiwayatView();
  @override
  State<_RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<_RiwayatView> {
  // Tablet master–detail: transaksi yang sedang ditampilkan di panel kanan.
  int? _selectedId;

  Future<void> _pickTanggal(BuildContext context, RiwayatState state) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: state.tanggal,
      locale: const Locale('id'),
    );
    if (d == null || !context.mounted) return;
    context.read<RiwayatCubit>().setTanggal(d);
  }

  Future<void> _pickRange(BuildContext context, RiwayatState state) async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: state.range,
      locale: const Locale('id'),
    );
    if (r == null || !context.mounted) return;
    context.read<RiwayatCubit>().setRange(r);
  }

  // Tanggal lokal tanpa paket intl: "Kam, 9 Okt 2026" / "1 Okt – 9 Okt 2026".
  String _label(BuildContext context, RiwayatState state) {
    final loc = MaterialLocalizations.of(context);
    if (!state.rangeMode) return loc.formatMediumDate(state.tanggal);
    final r = state.range;
    return '${loc.formatShortMonthDay(r.start)} – ${loc.formatShortMonthDay(r.end)} ${loc.formatYear(r.end)}';
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<RiwayatCubit, RiwayatState>(
        listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
        listener: (context, state) => toastError(context, state.error!),
        builder: (context, state) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final fg = dark ? Colors.white : ZK.slate900;
          final muted = dark ? Colors.white70 : ZK.slate500;
          final lineColor = dark ? ZK.lineDark : ZK.line;
          final summaryBg = dark ? ZK.cardDark : ZK.brand50;
          final tablet = isTablet(context);
          final list = Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: SizedBox(
                  height: 46,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _dateButton(context, state, dark)),
                      const SizedBox(width: 8),
                      _segmented(context, state, dark),
                    ],
                  ),
                ),
              ),
              // Ringkasan di luar daftar → tetap terlihat saat scroll.
              if (!state.loading && state.data.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: summaryBg, borderRadius: r12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${state.data.length} transaksi',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : ZK.brand700)),
                        Text(rupiah(state.total),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: fg)),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: state.loading
                    ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                    : state.data.isEmpty
                        ? const EmptyState(
                            icon: Icons.history,
                            title: 'Belum ada transaksi',
                            description: 'Coba pilih tanggal lain.')
                        : RefreshIndicator(
                            color: ZK.primary,
                            onRefresh: () => context.read<RiwayatCubit>().load(),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: state.data.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: lineColor),
                              itemBuilder: (_, i) =>
                                  _row(context, state.data[i], fg, muted, dark, tablet),
                            ),
                          ),
              ),
            ],
          );
          return HeroShell(
            child: SafeArea(
              top: false,
              bottom: false,
              child: !tablet
                  ? list
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: list),
                        VerticalDivider(width: 1, color: lineColor),
                        Expanded(
                          flex: 3,
                          child: _selectedId == null
                              ? const EmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Pilih transaksi',
                                  description: 'Detail transaksi tampil di sini.')
                              : RiwayatDetailPage(
                                  key: ValueKey(_selectedId), id: _selectedId!, embedded: true),
                        ),
                      ],
                    ),
            ),
          );
        },
      );

  Widget _dateButton(BuildContext context, RiwayatState state, bool dark) => Material(
        color: dark ? ZK.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: r12, side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
        child: InkWell(
          borderRadius: r12,
          onTap: () => state.rangeMode ? _pickRange(context, state) : _pickTanggal(context, state),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: dark ? Colors.white : ZK.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_label(context, state),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : ZK.primary)),
                ),
                if (!state.rangeMode && !state.isToday)
                  InkWell(
                    onTap: () => context.read<RiwayatCubit>().resetToToday(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: dark ? ZK.primary.withValues(alpha: 0.18) : ZK.brand50,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Hari ini',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ZK.primary)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _segmented(BuildContext context, RiwayatState state, bool dark) {
    Widget opt(String label, bool active, bool range) => Expanded(
          child: GestureDetector(
            onTap: () => context.read<RiwayatCubit>().setMode(range),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: active ? ZK.primary : null, borderRadius: r12),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : (dark ? Colors.white70 : ZK.slate500))),
            ),
          ),
        );
    return Container(
      width: 120,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r12,
        border: Border.all(color: dark ? ZK.lineDark : ZK.brand200),
      ),
      child: Row(children: [opt('Hari', !state.rangeMode, false), opt('Rentang', state.rangeMode, true)]),
    );
  }

  Widget _row(BuildContext context, Penjualan p, Color fg, Color muted, bool dark, bool tablet) {
    final selected = tablet && p.id == _selectedId;
    return InkWell(
      borderRadius: r12,
      onTap: () => tablet
          ? setState(() => _selectedId = p.id)
          : Navigator.of(context).push(MaterialPageRoute(builder: (_) => RiwayatDetailPage(id: p.id))),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: selected ? 10 : 0),
        decoration: selected
            ? BoxDecoration(
                color: dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
                borderRadius: r12,
                border: Border.all(color: ZK.primary))
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                  const SizedBox(height: 2),
                  Text([p.tanggal ?? '-', if (p.jam != null) p.jam!].join(' · '),
                      style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rupiah(p.total), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                if (p.jenisBayar != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: dark ? ZK.primary.withValues(alpha: 0.18) : ZK.brand50,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(p.jenisBayar!,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : ZK.brand700)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
