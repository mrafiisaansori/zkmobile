import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../data/transaksi_repository.dart';
import '../widgets/transaksi_detail_sheet.dart';

// Padanan lib/admin_transaksi_page.dart lama — riwayat SELURUH kasir (beda
// dari riwayat_page.dart yang scope-nya transaksi kasir sendiri). Detail
// ditampilkan lewat sheet (bukan halaman penuh) supaya tidak perlu urus
// sidebar tablet untuk sekadar lihat isi nota.
//
// Filter tanggal/rentang & status dibaca via closure atas field lokal (sama
// seperti pola tab status di AdminReturPage/AdminPembelianPage) — ListCubit<T>
// generik sudah mendukung load/loadMore/refresh lewat fetchPage({search,
// page}), jadi tidak perlu Cubit khusus meski filternya date-range.
class AdminTransaksiPage extends StatefulWidget {
  const AdminTransaksiPage({super.key});
  @override
  State<AdminTransaksiPage> createState() => _AdminTransaksiPageState();
}

class _AdminTransaksiPageState extends State<AdminTransaksiPage> {
  final _repo = TransaksiRepository();
  late final _cubit = ListCubit<Penjualan>(fetchPage: _fetchPage)..load();
  bool _rangeMode = false;
  DateTime _tanggal = DateTime.now();
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 6)), end: DateTime.now());
  int _status = 1;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _cubit.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _cubit.close();
    super.dispose();
  }

  String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<List<Penjualan>> _fetchPage({String? search, int page = 1}) {
    final dari = _rangeMode ? _iso(_range.start) : _iso(_tanggal);
    final sampai = _rangeMode ? _iso(_range.end) : _iso(_tanggal);
    return _repo.list(dari: dari, sampai: sampai, status: _status, page: page);
  }

  void _setMode(bool range) {
    if (range == _rangeMode) return;
    setState(() => _rangeMode = range);
    _cubit.load();
  }

  Future<void> _pickTanggal() async {
    final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDate: _tanggal,
        locale: const Locale('id'));
    if (d == null) return;
    setState(() => _tanggal = d);
    _cubit.load();
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _range,
        locale: const Locale('id'));
    if (r == null) return;
    setState(() => _range = r);
    _cubit.load();
  }

  void _setStatus(int s) {
    if (s == _status) return;
    setState(() => _status = s);
    _cubit.load();
  }

  Future<void> _lihat(Penjualan p) async {
    try {
      final full = await _repo.detail(p.id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TransaksiDetailSheet(trx: full),
      );
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _batalkan(Penjualan p) async {
    final ok = await confirmDialog(context,
        title: 'Batalkan transaksi?',
        message: 'Batalkan nota ${p.label}? Stok akan dikembalikan.',
        danger: true);
    if (!ok) return;
    try {
      await _repo.voidTx(p.id);
      if (mounted) toastOk(context, 'Transaksi dibatalkan');
      _cubit.load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    return BlocProvider.value(
      value: _cubit,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  _chip('Tanggal', !_rangeMode, dark, () => _setMode(false)),
                  const SizedBox(width: 8),
                  _chip('Rentang', _rangeMode, dark, () => _setMode(true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: OutlinedButton.icon(
                onPressed: _rangeMode ? _pickRange : _pickTanggal,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                    _rangeMode ? '${_iso(_range.start)} → ${_iso(_range.end)}' : _iso(_tanggal),
                    style: const TextStyle(fontSize: 12.5)),
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
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _statusChip('Sah', 1, dark),
                  ),
                  _statusChip('Batal', 0, dark),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<ListCubit<Penjualan>, ListState<Penjualan>>(
                builder: (context, state) {
                  final loading = state.status == ListStatus.loading;
                  final loadingMore = state.status == ListStatus.loadingMore;
                  final data = state.items;
                  if (loading) {
                    return const Center(child: CircularProgressIndicator(color: ZK.primary));
                  }
                  if (data.isEmpty) {
                    return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Tidak ada transaksi',
                        description: 'Coba ubah periode atau status.');
                  }
                  return RefreshIndicator(
                    color: ZK.primary,
                    onRefresh: () => _cubit.load(),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: data.length + (loadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= data.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: ZK.primary))),
                          );
                        }
                        final p = data[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dark ? ZK.cardDark : Colors.white,
                            borderRadius: r14,
                            border: Border.all(color: lineColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 46,
                                width: 46,
                                decoration: BoxDecoration(
                                    color: dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.receipt_long_outlined, color: ZK.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                    const SizedBox(height: 2),
                                    Text(
                                        [
                                          if (p.tanggal != null) p.tanggal!,
                                          if (p.jam != null) p.jam!,
                                          p.namaKasir ?? '-',
                                          if (p.jenisBayar != null) p.jenisBayar!,
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: muted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(rupiah(p.total),
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _lihat(p),
                                          tooltip: 'Lihat',
                                          icon: Icon(Icons.visibility_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      if (p.status == 1)
                                        IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _batalkan(p),
                                            tooltip: 'Batalkan',
                                            icon: const Icon(Icons.block, size: 18, color: ZK.rose)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, bool dark, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
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
        ),
      );

  Widget _statusChip(String label, int status, bool dark) {
    final active = _status == status;
    return GestureDetector(
      onTap: () => _setStatus(status),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 32,
        decoration: BoxDecoration(
          color: active ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(999),
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
