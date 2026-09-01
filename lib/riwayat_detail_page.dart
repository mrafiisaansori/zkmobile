import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'printer.dart';
import 'sheets.dart';
import 'shell.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/kasir/riwayat/[id]/page.tsx — detail satu transaksi,
// kirim struk WA, dan cetak struk ke printer thermal Bluetooth.
class RiwayatDetailPage extends StatefulWidget {
  final int id;
  const RiwayatDetailPage({super.key, required this.id});
  @override
  State<RiwayatDetailPage> createState() => _RiwayatDetailPageState();
}

class _RiwayatDetailPageState extends State<RiwayatDetailPage> {
  Penjualan? _trx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await Api.penjualanDetail(widget.id);
      if (mounted) setState(() => _trx = t);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _kirimWA() async {
    if (!Session.isPro) {
      toastError(context, 'Kirim struk WhatsApp hanya tersedia untuk paket PRO/BUSINESS.');
      return;
    }
    final nomor = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WaNumberSheet(),
    );
    if (nomor == null || nomor.isEmpty) return;
    try {
      final ok = await Api.kirimWA(widget.id, nomor);
      if (!mounted) return;
      if (ok) {
        toastOk(context, 'Struk terkirim ke WhatsApp');
      } else {
        toastError(context, 'Gagal mengirim struk');
      }
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  void _cetak() {
    final t = _trx;
    if (t == null) return;
    final receipt = PrintableReceipt(
      noNota: t.label,
      tanggal: [t.tanggal ?? '-', if (t.jam != null) t.jam!].join(' '),
      items: [
        for (final d in t.detail)
          ReceiptLine(d.namaProduk, d.qty, d.hargaJual, d.subtotal, d.modifier)
      ],
      total: t.total,
      kasir: t.namaKasir,
      metode: t.jenisBayar,
      status: t.statusBayar,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrinterPickerSheet(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _trx;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white70 : ZK.slate500;
    final cardColor = dark ? ZK.cardDark : Colors.white;
    final lineColor = dark ? ZK.lineDark : ZK.line;
    final heroContent = HeroShell(
      child: SafeArea(
        top: false,
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: ZK.primary))
            : t == null
                ? Center(
                    child: Text('Transaksi tidak ditemukan', style: TextStyle(color: fg)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: r12,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 18, color: fg),
                              const SizedBox(width: 6),
                              Text('Kembali',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Detail Transaksi',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: r14,
                          border: Border.all(color: lineColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Nota ${t.label}',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
                                ),
                                _statusBadge(t.status == 1, dark),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                                [
                                  t.tanggal ?? '-',
                                  if (t.jam != null)
                                    t.jam!.substring(0, t.jam!.length > 5 ? 5 : t.jam!.length),
                                  if (t.jenisBayar != null) t.jenisBayar!,
                                ].join(' · '),
                                style: TextStyle(fontSize: 13, color: muted)),
                            if (t.namaKasir != null) ...[
                              const SizedBox(height: 4),
                              Text('Kasir: ${t.namaKasir}',
                                  style: TextStyle(fontSize: 12, color: muted)),
                            ],
                            if (t.namaMember != null) ...[
                              const SizedBox(height: 4),
                              Text('Member: ${t.namaMember}',
                                  style: TextStyle(fontSize: 12, color: muted)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: _cetak,
                                icon: const Icon(Icons.print_outlined, size: 17),
                                label: const Text('Cetak Struk'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: dark ? Colors.white : ZK.primary,
                                    side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: _kirimWA,
                                icon: const Icon(Icons.message_outlined, size: 17),
                                label: const Text('Kirim WA'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: dark ? Colors.white : ZK.primary,
                                    side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200),
                                    shape: const RoundedRectangleBorder(borderRadius: r12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: r14,
                          border: Border.all(color: lineColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Item',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                            const SizedBox(height: 10),
                            if (t.detail.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text('Detail item tidak tersedia',
                                    style: TextStyle(
                                        fontSize: 12, color: dark ? Colors.white38 : ZK.slate400)),
                              )
                            else
                              for (final d in t.detail) _itemRow(d, fg),
                            Divider(height: 20, color: lineColor),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style:
                                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted)),
                                Text(rupiah(t.total),
                                    style: TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w900, color: fg)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
    // heroContent sama untuk phone & tablet, cuma chrome di sekelilingnya
    // beda. Tablet: sidebar sama seperti halaman lain di dalam shell, walau
    // halaman ini di-push di atas shell (bukan salah satu tab-nya).
    if (isTablet(context)) {
      return Scaffold(
        backgroundColor: dark ? ZK.bgDark : ZK.background,
        body: Row(
          children: [
            TabletSidebar(
              selectedIndex: 4,
              shiftActive: KasirShellState.current?.shiftActiveValue ?? true,
              onSelect: (i) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                KasirShellState.current?.goTo(i);
              },
            ),
            Expanded(child: heroContent),
          ],
        ),
      );
    }
    return Scaffold(backgroundColor: dark ? ZK.bgDark : ZK.background, body: heroContent);
  }

  Widget _statusBadge(bool sah, bool dark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sah ? const Color(0xFFECFDF5) : ZK.rose50,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(sah ? 'Sah' : 'Batal',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sah ? const Color(0xFF059669) : ZK.rose)),
      );

  Widget _itemRow(DetailPenjualan d, Color fg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.qty}x ${d.namaProduk}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                  if (d.modifier != null && d.modifier!.isNotEmpty)
                    Text(d.modifier!,
                        style: const TextStyle(fontSize: 11, color: ZK.primary)),
                ],
              ),
            ),
            Text(rupiah(d.subtotal),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      );
}
