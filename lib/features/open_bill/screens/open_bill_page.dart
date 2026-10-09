import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/offline/catalog_cache.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../pos/cubit/cart_cubit.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/open_bill_cubit.dart';

// Padanan src/app/kasir/open-bill/page.tsx.
class OpenBillPage extends StatelessWidget {
  const OpenBillPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => OpenBillCubit()..load(),
        child: const _OpenBillView(),
      );
}

class _OpenBillView extends StatefulWidget {
  const _OpenBillView();
  @override
  State<_OpenBillView> createState() => _OpenBillViewState();
}

class _OpenBillViewState extends State<_OpenBillView> {
  final _search = TextEditingController();

  static const _tabs = [
    ('OPEN', 'Aktif'),
    ('PAID', 'Lunas'),
    ('CANCELLED', 'Batal'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Draft bill belum punya ID server, jadi "dibuka" bukan lewat detail bill
  // sungguhan — item-nya dituang balik ke keranjang biasa lalu diarahkan ke
  // POS, sama seperti draft transaksi offline lain: tambah/bayar lewat alur
  // checkout offline yang sudah ada.
  Future<void> _bukaPending(BuildContext context, QueuedSale item) async {
    final cart = context.read<CartCubit>();
    cart.clear();
    final produk = await readCachedProduk();
    final items = (item.body['items'] as List).cast<Map>();
    for (final it in items) {
      final p = produk.where((x) => x.id == it['id_produk']).firstOrNull;
      if (p == null) continue;
      for (var i = 0; i < (it['qty'] as int); i++) {
        cart.addItem(p);
      }
    }
    if (!context.mounted) return;
    await context.read<OpenBillCubit>().removePending(item.localId);
    if (!context.mounted) return;
    context.read<ShellCubit>().openPos();
  }

  Future<void> _hapusPending(BuildContext context, QueuedSale item) async {
    final ok = await confirmDialog(context,
        title: 'Batalkan bill ini?',
        message:
            'Bill "${item.label}" belum pernah terkirim ke server dan akan dihapus permanen.',
        danger: true);
    if (!ok) return;
    if (!context.mounted) return;
    await context.read<OpenBillCubit>().removePending(item.localId);
    if (context.mounted) toastOk(context, 'Bill dibatalkan');
  }

  // Buka bill di POS: muat detail ke keranjang lalu pindah tab.
  Future<void> _buka(BuildContext context, OpenBill b) async {
    try {
      final full = await context.read<OpenBillCubit>().openBillDetail(b.id);
      if (!context.mounted) return;
      context.read<CartCubit>().loadBill(full);
      context.read<ShellCubit>().openPos();
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> _batalkan(BuildContext context, OpenBill b) async {
    final ok = await confirmDialog(context,
        title: 'Batalkan bill?',
        message: 'Bill ${b.noBill ?? b.id} akan dibatalkan.',
        danger: true);
    if (!ok) return;
    if (!context.mounted) return;
    final cubit = context.read<OpenBillCubit>();
    final success = await cubit.cancelBill(b.id);
    if (!context.mounted) return;
    if (success) {
      // Bill yang sama mungkin sedang terbuka di keranjang Kasir: lepaskan,
      // supaya tab Kasir tidak lagi menampilkan bill yang sudah batal.
      final cart = context.read<CartCubit>();
      if (cart.state.bill?.id == b.id) cart.clear();
      toastOk(context, 'Open bill dibatalkan');
    } else {
      toastError(context, cubit.state.error ?? 'Gagal membatalkan bill');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return MultiBlocListener(
      listeners: [
        // Padanan goToOpenBill() lama yang me-refresh _openBillKey secara
        // eksplisit — sekarang halaman ini sendiri yang dengar perpindahan
        // tab dari ShellCubit dan refresh dirinya saat ditampilkan.
        BlocListener<ShellCubit, ShellState>(
          listenWhen: (prev, curr) => prev.tab != curr.tab && curr.tab == 2,
          listener: (context, state) => context.read<OpenBillCubit>().refresh(),
        ),
      ],
      child: HeroShell(
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
                    onChanged: (v) => context.read<OpenBillCubit>().onSearchChanged(v),
                    style: TextStyle(color: dark ? Colors.white : ZK.ink),
                    decoration: InputDecoration(
                      hintText: 'Cari nama pelanggan / no bill...',
                      hintStyle:
                          TextStyle(color: dark ? Colors.white60 : ZK.slate500, fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          size: 20, color: dark ? Colors.white60 : ZK.slate400),
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
              BlocBuilder<OpenBillCubit, OpenBillState>(
                builder: (context, state) => SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final t in _tabs)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => context.read<OpenBillCubit>().setStatus(t.$1),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: state.status == t.$1
                                    ? ZK.primary
                                    : (dark ? ZK.cardDark : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: state.status == t.$1
                                        ? ZK.primary
                                        : (dark ? ZK.lineDark : ZK.brand200)),
                              ),
                              child: Text(t.$2,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: state.status == t.$1
                                          ? Colors.white
                                          : (dark ? Colors.white70 : ZK.slate500))),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: BlocConsumer<OpenBillCubit, OpenBillState>(
                  listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
                  listener: (context, state) => toastError(context, state.error!),
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(
                          child: CircularProgressIndicator(color: ZK.primary));
                    }
                    if (state.data.isEmpty &&
                        (state.status != 'OPEN' || state.pendingBills.isEmpty)) {
                      return const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Belum ada open bill',
                          description: 'Simpan keranjang sebagai bill dari halaman Kasir.');
                    }
                    final cards = [
                      if (state.status == 'OPEN')
                        for (final p in state.pendingBills) _pendingCard(context, p, dark),
                      for (final b in state.data) _card(context, b, dark),
                    ];
                    const pad = EdgeInsets.fromLTRB(16, 10, 16, 20);
                    return RefreshIndicator(
                      color: ZK.primary,
                      onRefresh: () => context.read<OpenBillCubit>().refresh(),
                      child: isTablet(context)
                          ? GridView(
                              padding: pad,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 360,
                                  mainAxisExtent: 112, // cukup untuk nama, member, no bill, catatan
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10),
                              children: cards,
                            )
                          : ListView.separated(
                              padding: pad,
                              itemCount: cards.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => cards[i],
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kerangka kartu bill: ubin kiri 52×52 · isi · kanan · menu ⋮. Tap kartu = buka.
  Widget _billCard({
    required bool dark,
    required Widget tile,
    required Color tileBg,
    required List<Widget> body,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onCancel,
    Color? border,
  }) =>
      Material(
        color: dark ? ZK.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: r14, side: BorderSide(color: border ?? (dark ? ZK.lineDark : ZK.line))),
        child: InkWell(
          borderRadius: r14,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: tileBg, borderRadius: r12),
                  child: tile,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: body,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
                if (onCancel != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: dark ? Colors.white60 : ZK.slate500),
                    onSelected: (_) => onCancel(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'cancel',
                          child: Text('Batalkan',
                              style: TextStyle(fontWeight: FontWeight.w700, color: ZK.rose))),
                    ],
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );

  Widget _pendingCard(BuildContext context, QueuedSale q, bool dark) {
    final rejected = q.status == 'failed';
    final tone = rejected ? ZK.rose : ZK.amber700;
    return _billCard(
      dark: dark,
      border: tone.withValues(alpha: 0.3),
      tileBg: rejected ? softBg(ZK.rose, ZK.rose50, dark) : softBg(ZK.amber700, ZK.amber50, dark),
      tile: Icon(rejected ? Icons.error_outline : Icons.cloud_off, color: tone),
      onTap: () => _bukaPending(context, q),
      onCancel: () => _hapusPending(context, q),
      body: [
        Text(q.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
        Text(
            rejected
                ? 'Ditolak server: ${q.errorMessage ?? '-'}'
                : 'Belum tersinkron: ketuk untuk tambah item / bayar.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: rejected ? ZK.rose : (dark ? Colors.white60 : ZK.slate500))),
      ],
    );
  }

  Widget _card(BuildContext context, OpenBill b, bool dark) {
    final aktif = b.status == 'OPEN';
    final meja = b.tableNo?.isNotEmpty == true ? b.tableNo! : '–';
    return _billCard(
      dark: dark,
      tileBg: dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
      tile: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('MEJA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ZK.brand700)),
          FittedBox(
            child: Text(meja,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ZK.primary)),
          ),
        ],
      ),
      onTap: aktif ? () => _buka(context, b) : null,
      onCancel: aktif ? () => _batalkan(context, b) : null,
      body: [
        Text(b.customerName?.isNotEmpty == true ? b.customerName! : 'Tanpa nama',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
        if (b.member != null || b.memberId != null)
          Row(
            children: [
              const Icon(Icons.person, size: 13, color: ZK.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(b.member == null ? 'Member' : 'Member · ${b.member!.nama}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ZK.primary)),
              ),
            ],
          ),
        Text(
            [
              if (b.noBill != null) b.noBill!,
              if (b.kasir != null) b.kasir!,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
        if (b.note != null)
          Text(b.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: ZK.primary)),
      ],
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(rupiah(b.total),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: dark ? Colors.white : ZK.slate900)),
          const SizedBox(height: 4),
          _statusBadge(b.status, dark),
        ],
      ),
    );
  }

  Widget _statusBadge(String s, bool dark) {
    final (bg, fg, label) = switch (s) {
      'PAID' => (softBg(ZK.success, ZK.successBg, dark), okTone(dark), 'Lunas'),
      'CANCELLED' => (softBg(ZK.rose, ZK.rose50, dark), ZK.rose, 'Batal'),
      _ => (
          dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
          dark ? Colors.white : ZK.brand700,
          'Aktif'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
