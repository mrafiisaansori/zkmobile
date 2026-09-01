import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'catalog_cache.dart';
import 'main.dart';
import 'models.dart';
import 'offline_queue.dart';
import 'shell.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/kasir/open-bill/page.tsx.
class OpenBillPage extends StatefulWidget {
  const OpenBillPage({super.key});
  @override
  State<OpenBillPage> createState() => OpenBillPageState();
}

class OpenBillPageState extends State<OpenBillPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _status = 'OPEN';
  List<OpenBill> _data = [];
  List<QueuedSale> _pendingBills = [];
  bool _loading = true;

  static const _tabs = [
    ('OPEN', 'Aktif'),
    ('PAID', 'Lunas'),
    ('CANCELLED', 'Batal'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    // Bill baru yang dibuat offline belum punya ID server — belum bisa
    // dibuka/dibayar/dibatalkan sampai berhasil disinkron, tapi tetap
    // ditampilkan di tab Aktif supaya tidak "hilang" dari pandangan kasir.
    final q = await getOfflineQueue();
    if (mounted) setState(() => _pendingBills = q.where((e) => e.endpoint == '/open-bill').toList());
    try {
      final r = await Api.openBills(status: _status, search: _search.text);
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Draft bill belum punya ID server, jadi "dibuka" bukan lewat detail bill
  // sungguhan — item-nya dituang balik ke keranjang biasa lalu diarahkan ke
  // POS, sama seperti draft transaksi offline lain: tambah/bayar lewat alur
  // checkout offline yang sudah ada.
  Future<void> _bukaPending(QueuedSale item) async {
    Cart.i.clear();
    final produk = await readCachedProduk();
    final items = (item.body['items'] as List).cast<Map>();
    for (final it in items) {
      final p = produk.where((x) => x.id == it['id_produk']).firstOrNull;
      if (p == null) continue;
      for (var i = 0; i < (it['qty'] as int); i++) {
        Cart.i.addItem(p);
      }
    }
    await removeFromQueue(item.localId);
    if (!mounted) return;
    KasirShell.of(context).openPos();
  }

  Future<void> _hapusPending(QueuedSale item) async {
    final ok = await confirmDialog(context,
        title: 'Batalkan bill ini?',
        message:
            'Bill "${item.label}" belum pernah terkirim ke server dan akan dihapus permanen.',
        danger: true);
    if (!ok) return;
    await removeFromQueue(item.localId);
    if (mounted) toastOk(context, 'Bill dibatalkan');
    _load();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  // Buka bill di POS: muat detail ke keranjang lalu pindah tab.
  Future<void> _buka(OpenBill b) async {
    try {
      final full = await Api.openBill(b.id);
      Cart.i.loadBill(full);
      if (!mounted) return;
      KasirShell.of(context).openPos();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _batalkan(OpenBill b) async {
    final ok = await confirmDialog(context,
        title: 'Batalkan bill?',
        message: 'Bill ${b.noBill ?? b.id} akan dibatalkan.',
        danger: true);
    if (!ok) return;
    try {
      await Api.cancelBill(b.id);
      if (!mounted) return;
      toastOk(context, 'Open bill dibatalkan');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HeroShell(
        child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: SizedBox(
                height: 46,
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  style: TextStyle(color: dark ? Colors.white : ZK.ink),
                  decoration: InputDecoration(
                    hintText: 'Cari nama pelanggan / no bill...',
                    hintStyle:
                        TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        size: 20, color: dark ? Colors.white54 : ZK.slate400),
                    filled: true,
                    fillColor: dark ? ZK.cardDark : Colors.white,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: r12,
                        borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: r12,
                        borderSide: BorderSide(color: ZK.primary, width: 1.6)),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final t in _tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _status = t.$1);
                          _load();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _status == t.$1
                                ? ZK.primary
                                : (dark ? ZK.cardDark : Colors.white),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: _status == t.$1
                                    ? ZK.primary
                                    : (dark ? ZK.lineDark : ZK.brand200)),
                          ),
                          child: Text(t.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _status == t.$1
                                      ? Colors.white
                                      : (dark ? Colors.white70 : ZK.slate500))),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: ZK.primary))
                  : (_data.isEmpty && (_status != 'OPEN' || _pendingBills.isEmpty))
                      ? const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Belum ada open bill',
                          description:
                              'Simpan keranjang sebagai bill dari halaman Kasir.')
                      : RefreshIndicator(
                          color: ZK.primary,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                            children: [
                              if (_status == 'OPEN')
                                for (final p in _pendingBills) _pendingCard(p, dark),
                              for (final b in _data) _card(b, dark),
                            ],
                          ),
                        ),
            ),
          ],
        ),
        ),
    );
  }

  Widget _pendingCard(QueuedSale q, bool dark) {
    final rejected = q.status == 'failed';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r14,
        border: Border.all(color: rejected ? ZK.rose.withValues(alpha: 0.3) : ZK.amber700.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(rejected ? Icons.error_outline : Icons.cloud_off,
                  size: 16, color: rejected ? ZK.rose : ZK.amber700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(q.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.ink)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              rejected
                  ? 'Ditolak server: ${q.errorMessage ?? '-'}'
                  : 'Belum tersinkron ke server — buka untuk tambah item / bayar sekarang.',
              style: TextStyle(
                  fontSize: 12,
                  color: rejected ? ZK.rose : (dark ? Colors.white60 : ZK.slate500))),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: () => _hapusPending(q),
                style: OutlinedButton.styleFrom(
                    foregroundColor: ZK.rose,
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                child: const Text('Batalkan'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _bukaPending(q),
                style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                child: const Text('Buka'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(OpenBill b, bool dark) {
    final aktif = b.status == 'OPEN';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                child: Text(
                    b.customerName?.isNotEmpty == true
                        ? b.customerName!
                        : 'Tanpa nama',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.ink)),
              ),
              _statusBadge(b.status, dark),
            ],
          ),
          const SizedBox(height: 3),
          Text(
              [
                if (b.noBill != null) b.noBill!,
                'Meja ${b.tableNo?.isNotEmpty == true ? b.tableNo : '-'}',
                if (b.kasir != null) b.kasir!,
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
          if (b.note != null) ...[
            const SizedBox(height: 4),
            Text(b.note!,
                style: const TextStyle(fontSize: 12, color: ZK.primary)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(rupiah(b.total),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : ZK.slate900)),
              const Spacer(),
              if (aktif) ...[
                OutlinedButton(
                  onPressed: () => _batalkan(b),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: ZK.rose,
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: const Text('Batalkan'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _buka(b),
                  style: FilledButton.styleFrom(
                      backgroundColor: ZK.primary,
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: const Text('Buka'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String s, bool dark) {
    final (bg, fg, label) = switch (s) {
      'PAID' => (const Color(0xFFECFDF5), const Color(0xFF047857), 'Lunas'),
      'CANCELLED' => (ZK.rose50, ZK.rose, 'Batal'),
      _ => (
          dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
          dark ? Colors.white : ZK.brand700,
          'Aktif'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
