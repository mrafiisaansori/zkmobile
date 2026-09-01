import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'riwayat_detail_page.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/kasir/riwayat/page.tsx (daftar transaksi kasir).
class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});
  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  bool _rangeMode = false;
  DateTime _tanggal = DateTime.now();
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 6)), end: DateTime.now());
  List<Penjualan> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dari = _rangeMode ? _iso(_range.start) : _iso(_tanggal);
      final sampai = _rangeMode ? _iso(_range.end) : _iso(_tanggal);
      final r = await Api.riwayat(dari: dari, sampai: sampai);
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setMode(bool range) {
    if (range == _rangeMode) return;
    setState(() => _rangeMode = range);
    _load();
  }

  Future<void> _pickTanggal() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _tanggal,
      locale: const Locale('id'),
    );
    if (d == null) return;
    setState(() => _tanggal = d);
    _load();
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      locale: const Locale('id'),
    );
    if (r == null) return;
    setState(() => _range = r);
    _load();
  }

  int get _total => _data.fold(0, (s, p) => s + p.total);

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.slate900;
    final muted = dark ? Colors.white70 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    final summaryBg = dark ? ZK.cardDark : ZK.brand50;
    return HeroShell(
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  _modeChip('Tanggal', !_rangeMode, dark, () => _setMode(false)),
                  const SizedBox(width: 8),
                  _modeChip('Rentang', _rangeMode, dark, () => _setMode(true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _rangeMode ? _pickRange : _pickTanggal,
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                          _rangeMode
                              ? '${_iso(_range.start)} → ${_iso(_range.end)}'
                              : _iso(_tanggal),
                          style: const TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: dark ? ZK.cardDark : Colors.white,
                        foregroundColor: dark ? Colors.white : ZK.primary,
                        side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const RoundedRectangleBorder(borderRadius: r12),
                      ),
                    ),
                  ),
                  if (!_rangeMode && !_isToday(_tanggal)) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _tanggal = DateTime.now());
                          _load();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dark ? Colors.white : ZK.primary,
                          side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                          shape: const RoundedRectangleBorder(borderRadius: r12),
                        ),
                        child: const Text('Hari Ini', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_loading && _data.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: summaryBg, borderRadius: r12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_data.length} transaksi',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : ZK.brand700)),
                      Text(rupiah(_total),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: fg)),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                  : _data.isEmpty
                      ? const EmptyState(
                          icon: Icons.history,
                          title: 'Belum ada transaksi',
                          description: 'Coba pilih tanggal lain.')
                      : RefreshIndicator(
                          color: ZK.primary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: _data.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: lineColor),
                            itemBuilder: (_, i) => _row(_data[i], fg, muted),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool active, bool dark, VoidCallback onTap) => Expanded(
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

  Widget _row(Penjualan p, Color fg, Color muted) => InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => RiwayatDetailPage(id: p.id))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          p.tanggal ?? '-',
                          if (p.jam != null) p.jam!,
                          if (p.jenisBayar != null) p.jenisBayar!,
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ),
              Text(rupiah(p.total),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
            ],
          ),
        ),
      );
}
