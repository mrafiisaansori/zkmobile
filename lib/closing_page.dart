import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/kasir/closing/page.tsx — buka/tutup sesi kasir, catat kas
// masuk/keluar, dan tutup kasir dengan hitung selisih uang tunai.
class ClosingPage extends StatefulWidget {
  const ClosingPage({super.key});
  @override
  State<ClosingPage> createState() => _ClosingPageState();
}

class _ClosingPageState extends State<ClosingPage> {
  Map<String, dynamic>? _shift;
  Map<String, dynamic>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await Api.activeShift();
      if (mounted) setState(() => _shift = s);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bukaKasir() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BukaSesiSheet(),
    );
    if (ok == true) {
      setState(() => _result = null);
      _load();
    }
  }

  Future<void> _catatMutasi() async {
    final id = _shift?['ID'] as int?;
    if (id == null) return;
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MutasiSheet(shiftId: id),
    );
    if (done == true) _load();
  }

  Future<void> _tutupKasir() async {
    final id = _shift?['ID'] as int?;
    if (id == null) return;
    try {
      final preview = await Api.shiftClosePreview(id);
      if (!mounted) return;
      final closed = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CloseKasirSheet(shiftId: id, preview: preview),
      );
      if (closed != null) {
        setState(() {
          _shift = null;
          _result = closed;
        });
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate500;
    final cardColor = dark ? ZK.cardDark : Colors.white;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    return HeroShell(
      child: SafeArea(
        top: false,
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: ZK.primary))
            : RefreshIndicator(
                color: ZK.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (_shift == null && _result == null)
                      _bukaKasirCard(dark, fg, muted, cardColor, lineColor),
                    if (_result != null)
                      _resultCard(dark, fg, muted, cardColor, lineColor),
                    if (_shift != null) ..._shiftAktif(dark, fg, muted, cardColor, lineColor),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _bukaKasirCard(
          bool dark, Color fg, Color muted, Color cardColor, Color lineColor) =>
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
                onPressed: _bukaKasir,
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

  Widget _resultCard(
      bool dark, Color fg, Color muted, Color cardColor, Color lineColor) {
    final r = _result!;
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
              onPressed: _bukaKasir,
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

  List<Widget> _shiftAktif(
      bool dark, Color fg, Color muted, Color cardColor, Color lineColor) {
    final s = _shift!;
    final pv = (s['preview'] as Map<String, dynamic>?) ?? {};
    final methods = (pv['methods'] as List?) ?? [];
    final mutasiNet = ((pv['mutasi_out'] as num?) ?? 0) - ((pv['mutasi_in'] as num?) ?? 0);
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
                onPressed: _catatMutasi,
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
                onPressed: _tutupKasir,
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

// ===== Catat kas keluar/masuk =====
class _MutasiSheet extends StatefulWidget {
  final int shiftId;
  const _MutasiSheet({required this.shiftId});
  @override
  State<_MutasiSheet> createState() => _MutasiSheetState();
}

class _MutasiSheetState extends State<_MutasiSheet> {
  String _tipe = 'OUT';
  final _nominal = TextEditingController();
  final _ket = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nominal.dispose();
    _ket.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final n = parseRupiah(_nominal.text);
    if (n <= 0) {
      toastError(context, 'Nominal harus lebih dari 0');
      return;
    }
    setState(() => _loading = true);
    try {
      await Api.shiftMutasi(widget.shiftId, _tipe, n, keterangan: _ket.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
      toastOk(context, _tipe == 'OUT' ? 'Kas keluar dicatat' : 'Kas masuk dicatat');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                const SheetHeader(
                    title: 'Catat Kas Keluar / Masuk',
                    subtitle: 'Di luar penjualan, mis. ambil uang / tambah modal',
                    icon: Icons.swap_vert),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _tipeBtn(
                                'OUT', 'Kas Keluar', Icons.arrow_upward, ZK.rose, dark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tipeBtn('IN', 'Kas Masuk', Icons.arrow_downward,
                                const Color(0xFF10B981), dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Nominal'),
                      TextField(
                        controller: _nominal,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        inputFormatters: [RupiahInputFormatter()],
                        style: TextStyle(color: dark ? Colors.white : ZK.ink),
                        decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                      ),
                      const SizedBox(height: 14),
                      const FieldLabel('Keterangan (opsional)'),
                      TextField(
                          controller: _ket,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. Beli galon air', dark: dark)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Simpan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _tipeBtn(String tipe, String label, IconData icon, Color tone, bool dark) {
    final aktif = _tipe == tipe;
    return InkWell(
      onTap: () => setState(() => _tipe = tipe),
      borderRadius: r12,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: aktif ? tone.withValues(alpha: 0.1) : (dark ? ZK.cardDark : Colors.white),
          borderRadius: r12,
          border: Border.all(
              color: aktif ? tone : (dark ? ZK.lineDark : ZK.line), width: aktif ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: aktif ? tone : (dark ? Colors.white54 : ZK.slate500)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: aktif ? tone : (dark ? Colors.white70 : ZK.slate500))),
          ],
        ),
      ),
    );
  }
}

// ===== Tutup kasir: preview selisih + input uang fisik =====
class _CloseKasirSheet extends StatefulWidget {
  final int shiftId;
  final Map<String, dynamic> preview;
  const _CloseKasirSheet({required this.shiftId, required this.preview});
  @override
  State<_CloseKasirSheet> createState() => _CloseKasirSheetState();
}

class _CloseKasirSheetState extends State<_CloseKasirSheet> {
  final _actual = TextEditingController();
  final _catatan = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _actual.dispose();
    _catatan.dispose();
    super.dispose();
  }

  int get _expected => ((widget.preview['expected_cash'] as num?) ?? 0).toInt();
  int get _actualNum => parseRupiah(_actual.text);
  int get _selisih => _actualNum - _expected;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final res = await Api.shiftClose(widget.shiftId, _actualNum,
          catatan: _catatan.text.trim());
      if (!mounted) return;
      Navigator.pop(context, res);
      toastOk(context, 'Kasir berhasil ditutup');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.preview;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(
                    title: 'Tutup Kasir',
                    subtitle: 'Hitung & cocokkan uang tunai di laci',
                    icon: Icons.lock_outline),
                Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50,
                            borderRadius: r14),
                        child: Column(
                          children: [
                            _row('Modal awal', rupiah(((p['modal_awal'] as num?) ?? 0)), dark),
                            _row('Penjualan tunai',
                                '+ ${rupiah(((p['cash_sales'] as num?) ?? 0))}', dark),
                            _row('Kas masuk', '+ ${rupiah(((p['mutasi_in'] as num?) ?? 0))}',
                                dark),
                            _row('Kas keluar', '- ${rupiah(((p['mutasi_out'] as num?) ?? 0))}',
                                dark),
                            Divider(height: 16, color: dark ? ZK.lineDark : ZK.brand200),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Uang tunai seharusnya',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: dark ? Colors.white : ZK.ink)),
                                Text(rupiah(_expected),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: ZK.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Uang tunai hasil hitung di laci'),
                      TextField(
                        controller: _actual,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        autofocus: true,
                        inputFormatters: [RupiahInputFormatter()],
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : ZK.slate900),
                        decoration: sheetInput('0', prefix: 'Rp  ', dark: dark),
                      ),
                      if (_actual.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                              color: _selisih == 0
                                  ? const Color(0xFFECFDF5)
                                  : (_selisih < 0 ? ZK.rose50 : ZK.amber50),
                              borderRadius: r12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  _selisih == 0
                                      ? 'Cocok / pas'
                                      : (_selisih < 0 ? 'Kurang' : 'Lebih'),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selisih == 0
                                          ? const Color(0xFF059669)
                                          : (_selisih < 0 ? ZK.rose : ZK.amber700))),
                              Text(rupiah(_selisih.abs()),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _selisih == 0
                                          ? const Color(0xFF059669)
                                          : (_selisih < 0 ? ZK.rose : ZK.amber700))),
                            ],
                          ),
                        ),
                      ],
                      if (((p['non_cash_sales'] as num?) ?? 0) > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                            'Penjualan non-tunai (${rupiah(((p['non_cash_sales'] as num?) ?? 0))}) tidak dihitung di sini karena tidak ada uang fisik di laci.',
                            style: const TextStyle(fontSize: 11, color: ZK.slate400)),
                      ],
                      const SizedBox(height: 14),
                      const FieldLabel('Catatan (opsional)'),
                      TextField(
                          controller: _catatan,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. Selisih karena kembalian', dark: dark)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Tutup & Simpan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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

  Widget _row(String l, String v, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : ZK.muted)),
            Text(v,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : ZK.slate900)),
          ],
        ),
      );
}
