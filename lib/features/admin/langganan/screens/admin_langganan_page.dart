import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../midtrans/screens/midtrans_payment_page.dart';
import '../cubit/langganan_cubit.dart';

// Padanan src/app/admin/langganan/page.tsx. Pembayaran PRO jalan native via
// Midtrans Snap di WebView in-app (midtrans_payment_page.dart) — cuma
// "Hubungi BUSINESS" yang tetap buka WhatsApp (backend menolak buat tagihan
// BUSINESS otomatis, harus dikontak manual).
const _businessWaUrl =
    'https://wa.me/62859106997680?text=Halo%20Zona%20Kasir%2C%20saya%20ingin%20upgrade%20atau%20memperpanjang%20paket%20BUSINESS.';

const _statusLabel = {
  'UNPAID': 'Belum Dibayar',
  'PENDING': 'Menunggu Pembayaran',
  'PAID': 'Berhasil',
  'EXPIRED': 'Kedaluwarsa',
  'CANCELLED': 'Dibatalkan',
  'FAILED': 'Gagal',
};

const _paketLabels = {'BULANAN': '1 Bulan', '3_BULAN': '3 Bulan', '6_BULAN': '6 Bulan', 'TAHUNAN': '1 Tahun'};

class AdminLanggananPage extends StatelessWidget {
  const AdminLanggananPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => LanggananCubit(),
        child: const _AdminLanggananView(),
      );
}

class _AdminLanggananView extends StatefulWidget {
  const _AdminLanggananView();
  @override
  State<_AdminLanggananView> createState() => _AdminLanggananViewState();
}

class _AdminLanggananViewState extends State<_AdminLanggananView> {
  String _paket = 'BULANAN';

  Future<void> _openLink(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) toastError(context, 'Tidak bisa membuka link');
  }

  Future<void> _upgrade(BuildContext context) async {
    final cubit = context.read<LanggananCubit>();
    try {
      final payment = await cubit.upgrade(_paket);
      final url = payment.snapRedirectUrl;
      if (url == null) throw Exception('Link pembayaran tidak tersedia');
      if (!context.mounted) return;
      final status = await Navigator.of(context).push<String>(MaterialPageRoute(
          builder: (_) => MidtransPaymentPage(paymentId: payment.id, snapUrl: url)));
      if (!context.mounted) return;
      if (status == 'PAID') {
        toastOk(context, 'Pembayaran berhasil: plan PRO aktif');
      } else if (status == 'FAILED' || status == 'EXPIRED') {
        toastError(context, 'Pembayaran tidak berhasil');
      }
      cubit.load();
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    return BlocConsumer<LanggananCubit, LanggananState>(
      listener: (context, s) {
        if (s.status == LanggananStatus.error && s.error != null) {
          toastError(context, s.error!);
        }
      },
      builder: (context, s) {
        if (s.status == LanggananStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: ZK.primary));
        }
        final b = s.billing;
        final setting = s.setting;
        if (b == null || setting == null) {
          return Center(
            child: OutlinedButton(onPressed: () => context.read<LanggananCubit>().load(), child: const Text('Coba lagi')),
          );
        }
        final plan = b.plan;
        final tablet = isTablet(context);

        final statCards = [
          _statCard('Plan saat ini', plan, Icons.workspace_premium_outlined,
              plan == 'FREE' ? ZK.slate500 : ZK.primary, dark),
          _statCard('Masa aktif plan', b.proExpiresAt == null ? '-' : _fmtDateTime(b.proExpiresAt!),
              Icons.schedule_outlined, ZK.amber700, dark),
          _statCard(
              'Pembayaran terakhir',
              b.latest == null ? 'Belum ada' : (_statusLabel[b.latest!.status] ?? b.latest!.status),
              Icons.receipt_long_outlined,
              ZK.brand700,
              dark),
        ];

        return RefreshIndicator(
          color: ZK.primary,
          onRefresh: () => context.read<LanggananCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (tablet)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in statCards) ...[Expanded(child: c), const SizedBox(width: 10)],
                    ],
                  ),
                )
              else
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final c in statCards) ...[c, const SizedBox(height: 10)]]),
              const SizedBox(height: 4),
              if (plan == 'FREE') ...[
                _card(dark, child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          height: 32,
                          width: 32,
                          decoration: const BoxDecoration(color: ZK.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.workspace_premium, size: 17, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text('Kenapa upgrade ke PRO?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                      ]),
                      const SizedBox(height: 10),
                      for (final benefit in const [
                        'Tambah produk lebih banyak (FREE maksimal 20)',
                        'Multiple kasir sekaligus',
                        'Open Bill, voucher, pajak & service charge',
                        'Laporan lengkap & struk tanpa branding Zona Kasir',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: okTone(dark)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(benefit, style: TextStyle(fontSize: 12.5, color: fg))),
                            ],
                          ),
                        ),
                    ],
                  ),
                )),
                const SizedBox(height: 14),
              ],
              _card(dark, child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih Paket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 2),
                    Text('Bayar via Midtrans, plan aktif otomatis begitu berhasil.',
                        style: TextStyle(fontSize: 12, color: muted)),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: tablet ? 4 : 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _paketTile('BULANAN', '1 Bulan', setting.priceMonthly, null, dark, fg),
                        _paketTile('3_BULAN', '3 Bulan', setting.price3Months, 150000, dark, fg),
                        _paketTile('6_BULAN', '6 Bulan', setting.price6Months, 300000, dark, fg),
                        _paketTile('TAHUNAN', '1 Tahun', setting.priceYearly, 600000, dark, fg),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: s.paying ? null : () => _upgrade(context),
                        icon: s.paying
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.credit_card, size: 18),
                        label: Text('Upgrade ${_paketLabels[_paket]}',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        style: FilledButton.styleFrom(
                            backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openLink(_businessWaUrl),
                        icon: const Icon(Icons.chat, size: 17, color: Color(0xFF16A34A)),
                        label: const Text('Hubungi untuk BUSINESS',
                            style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            shape: const RoundedRectangleBorder(borderRadius: r12)),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 14),
              _card(dark, child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riwayat Pembayaran',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 10),
                    if (b.payments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Belum ada pembayaran',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: muted)),
                      )
                    else
                      for (final p in b.payments) _paymentRow(p, dark, fg, muted),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentRow(SubscriptionPayment p, bool dark, Color fg, Color muted) {
    final (bg, tone) = switch (p.status) {
      'PAID' => (dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50, dark ? Colors.white : ZK.brand700),
      'PENDING' => (softBg(ZK.amber700, ZK.amber50, dark), ZK.amber700),
      _ => (softBg(ZK.rose, ZK.rose50, dark), ZK.rose),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: r12, border: Border.all(color: dark ? ZK.lineDark : ZK.line)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${p.targetPlan} · ${p.paket}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                if (p.createdAt != null)
                  Text(_fmtDateTime(p.createdAt!), style: TextStyle(fontSize: 11, color: muted)),
              ],
            ),
          ),
          Text(rupiah(p.totalBayar),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(_statusLabel[p.status] ?? p.status,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: tone)),
          ),
        ],
      ),
    );
  }

  Widget _paketTile(String paket, String label, int price, int? coret, bool dark, Color fg) {
    final selected = _paket == paket;
    return InkWell(
      borderRadius: r14,
      onTap: () => setState(() => _paket = paket),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? ZK.primary.withValues(alpha: dark ? 0.22 : 0.08) : (dark ? ZK.bgDark : ZK.background),
          borderRadius: r14,
          border: Border.all(color: selected ? ZK.primary : (dark ? ZK.lineDark : ZK.line), width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? ZK.primary : ZK.slate500)),
            const SizedBox(height: 4),
            if (coret != null)
              Text(rupiah(coret),
                  style: const TextStyle(
                      fontSize: 10.5, color: ZK.slate500, decoration: TextDecoration.lineThrough)),
            Text(rupiah(price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: fg)),
          ],
        ),
      ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: dark ? Colors.white60 : ZK.slate500)),
          ],
        ),
      );

  Widget _card(bool dark, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: r14,
          border: Border.all(color: dark ? ZK.lineDark : ZK.line),
        ),
        child: child,
      );

  String _fmtDateTime(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final jam = d.hour.toString().padLeft(2, '0');
    final menit = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${bulan[d.month - 1]} ${d.year}, $jam:$menit';
  }
}
