import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/list_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../data/transaksi_repository.dart';
import '../../../../shared/widgets/report_kit.dart';
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
    final c = RColors.of(context);
    final periode = _rangeMode ? rangeLabel(context, _range) : dateLabel(context, _tanggal);
    return BlocProvider.value(
      value: _cubit,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(child: RDateButton(label: periode, onTap: _rangeMode ? _pickRange : _pickTanggal)),
                  const SizedBox(width: 8),
                  RSegmented<bool>(
                      width: 128,
                      options: const [('Hari', false), ('Rentang', true)],
                      selected: _rangeMode,
                      onChanged: _setMode),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: RSegmented<int>(
                  options: const [('Transaksi sah', 1), ('Dibatalkan', 0)], selected: _status, onChanged: _setStatus),
            ),
            Expanded(
              child: BlocBuilder<ListCubit<Penjualan>, ListState<Penjualan>>(
                builder: (context, state) {
                  final data = state.items;
                  if (state.status == ListStatus.loading || state.status == ListStatus.initial) {
                    return const Center(child: CircularProgressIndicator(color: ZK.primary));
                  }
                  if (state.status == ListStatus.error && data.isEmpty) {
                    return RError(message: state.error ?? 'Periksa koneksi internet.', onRetry: _cubit.load);
                  }
                  if (data.isEmpty) {
                    return EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: _status == 1 ? 'Tidak ada transaksi' : 'Tidak ada transaksi dibatalkan',
                        description: 'Belum ada nota pada $periode. Pilih periode lain.');
                  }
                  final loadingMore = state.status == ListStatus.loadingMore;
                  return RefreshIndicator(
                    color: ZK.primary,
                    onRefresh: () => _cubit.load(),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        return _row(data[i], c, first: i == 0, last: i == data.length - 1);
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

  // Daftar nota sebagai satu lembar bergaris (kartu pertama/terakhir membulat),
  // bukan tumpukan kartu terpisah — lebih mudah dipindai ke bawah.
  Widget _row(Penjualan p, RColors c, {required bool first, required bool last}) {
    final jam = (p.jam ?? '').length >= 5 ? p.jam!.substring(0, 5) : (p.jam ?? '');
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(
          left: BorderSide(color: c.line),
          right: BorderSide(color: c.line),
          top: BorderSide(color: c.line),
          bottom: last ? BorderSide(color: c.line) : BorderSide.none,
        ),
        borderRadius: BorderRadius.vertical(
            top: first ? const Radius.circular(14) : Radius.zero,
            bottom: last ? const Radius.circular(14) : Radius.zero),
      ),
      child: InkWell(
        onTap: () => _lihat(p),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.fg)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          if (_rangeMode && p.tanggal != null) p.tanggal!,
                          if (jam.isNotEmpty) jam,
                          p.namaKasir ?? '-',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rupiah(p.total),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.status == 1 ? c.fg : c.muted,
                          decoration: p.status == 1 ? null : TextDecoration.lineThrough,
                          fontFeatures: tabular)),
                  if (p.jenisBayar != null)
                    Text(p.jenisBayar!, style: TextStyle(fontSize: 11.5, color: c.muted)),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: c.muted),
                onSelected: (v) => v == 'void' ? _batalkan(p) : _lihat(p),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'lihat', child: Text('Lihat detail')),
                  if (p.status == 1)
                    const PopupMenuItem(
                        value: 'void',
                        child: Text('Batalkan transaksi',
                            style: TextStyle(fontWeight: FontWeight.w700, color: ZK.rose))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
