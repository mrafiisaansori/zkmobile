import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../models/cart_item.dart';
import '../../../shared/widgets/sheet_common.dart';

// ===== Keranjang (padanan components/pos/Cart.tsx) =====
class CartSheet extends StatelessWidget {
  final bool isPro;
  // Dipakai dua tempat: modal bottom sheet (ponsel) dan panel tetap di
  // sebelah kanan POS (tablet) — embedded=true buang tombol tutup & tinggi
  // tetap ala sheet karena parent-nya (Expanded) yang menentukan ukuran.
  final bool embedded;
  final VoidCallback onCheckout,
      onSaveBill,
      onUpdateBill,
      onCancelBill,
      onSplitBill,
      onPickMember;
  const CartSheet({
    super.key,
    required this.isPro,
    required this.onCheckout,
    required this.onSaveBill,
    required this.onUpdateBill,
    required this.onCancelBill,
    required this.onSplitBill,
    required this.onPickMember,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final body = BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) => Column(
        children: [
          SheetHeader(
            title: cart.billMode ? 'Edit Bill' : 'Keranjang',
            subtitle: cart.billMode && cart.bill?.noBill != null
                ? cart.bill!.noBill!
                : '${cart.items.length} item dipilih',
            showClose: !embedded,
            action: cart.items.isEmpty && !cart.billMode
                ? null
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'cancel') return onCancelBill();
                      // Kosongkan isi keranjang tanpa membuang konteks bill/member —
                      // CartCubit tidak punya method "clear items saja", jadi
                      // dibongkar lewat remove() per baris + setDiskon(0).
                      final cubit = context.read<CartCubit>();
                      for (final it in List<CartItem>.from(cart.items)) {
                        cubit.remove(it);
                      }
                      cubit.setDiskon(0);
                    },
                    itemBuilder: (_) => [
                      if (cart.items.isNotEmpty)
                        const PopupMenuItem(
                            value: 'clear',
                            child: Text('Kosongkan',
                                style: TextStyle(fontWeight: FontWeight.w700, color: ZK.rose))),
                      if (cart.billMode)
                        const PopupMenuItem(
                            value: 'cancel',
                            child: Text('Batalkan bill',
                                style: TextStyle(fontWeight: FontWeight.w700, color: ZK.rose))),
                    ],
                  ),
          ),
          Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
          if (isPro && !cart.billMode) _memberRow(context, cart, dark),
          Expanded(
            child: cart.items.isEmpty
                ? const EmptyState(
                    title: 'Keranjang masih kosong',
                    description: 'Pilih produk dari grid untuk mulai transaksi.')
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: dark ? ZK.lineDark : ZK.slate100),
                    itemBuilder: (_, i) {
                      void onQty(int q) {
                        final r = context.read<CartCubit>().updateQty(cart.items[i], q);
                        if (!r.ok) toastError(context, r.message!);
                      }

                      return Dismissible(
                        key: ValueKey(cart.items[i].lineId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => onQty(0),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                              color: dark ? ZK.rose.withValues(alpha: 0.16) : ZK.rose50, borderRadius: r12),
                          child: const Icon(Icons.delete_outline, color: ZK.rose),
                        ),
                        child: _CartRow(item: cart.items[i], onQty: onQty),
                      );
                    },
                  ),
          ),
          _footer(context, cart),
        ],
      ),
    );
    if (embedded) return DecoratedBox(decoration: sheetBox(dark), child: body);
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: sheetBox(dark),
      child: body,
    );
  }

  Widget _memberRow(BuildContext context, CartState cart, bool dark) => Padding(
        padding: EdgeInsets.fromLTRB(12, isTablet(context) ? 8 : 12, 12, 0),
        child: InkWell(
          onTap: onPickMember,
          borderRadius: r12,
          child: Container(
            padding: EdgeInsets.all(isTablet(context) ? 8 : 10),
            decoration: BoxDecoration(
              color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50,
              borderRadius: r12,
              border: Border.all(color: dark ? ZK.primary.withValues(alpha: 0.35) : ZK.brand100),
            ),
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: const BoxDecoration(color: ZK.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.person, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cart.member?.nama ?? 'Tanpa member',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : ZK.slate800)),
                      Text(cart.member == null ? 'Pilih member/customer' : 'Ganti member',
                          style: TextStyle(
                              fontSize: 11, color: dark ? Colors.white60 : ZK.slate500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: dark ? Colors.white60 : ZK.slate400),
              ],
            ),
          ),
        ),
      );

  Widget _footer(BuildContext context, CartState cart) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final billMode = cart.billMode;
    // Footer lebih ringkas di tablet — panel keranjang permanen di sana,
    // jadi ruang yang dihemat di sini balik jadi tinggi tambahan buat daftar
    // item yang bisa discroll (lebih gampang direview sebelum bayar).
    final tablet = isTablet(context);
    final gapSm = tablet ? 6.0 : 10.0;
    final gapMd = tablet ? 8.0 : 12.0;
    final btnH = tablet ? 46.0 : 52.0;
    final empty = cart.items.isEmpty;
    final split = _sideBtn(Icons.call_split, 'Split Bill', empty ? null : onSplitBill);
    final simpan = billMode
        ? _sideBtn(Icons.save_outlined, 'Simpan', empty ? null : onUpdateBill)
        : _sideBtn(Icons.assignment_outlined, 'Simpan Bill', empty ? null : onSaveBill);
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, tablet ? 8 : 12, 16, (tablet ? 8 : 12) + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        border: Border(top: BorderSide(color: dark ? ZK.lineDark : ZK.brand100)),
      ),
      child: Column(
        children: [
          _sumRow('Subtotal', rupiah(cart.subtotal), dark),
          if (cart.diskon > 0)
            _sumRow('Potongan', '- ${rupiah(cart.diskon)}', dark, color: ZK.rose),
          if (cart.voucher != null)
            _sumRow('Voucher ${cart.voucher!.kode}', '- ${rupiah(cart.voucher!.diskon)}', dark,
                color: ZK.rose),
          _DiskonFold(
              subtotal: cart.subtotal,
              diskon: cart.diskon,
              onChanged: context.read<CartCubit>().setDiskon),
          SizedBox(height: gapSm),
          Divider(height: 1, color: dark ? ZK.lineDark : ZK.slate100),
          SizedBox(height: gapSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: dark ? Colors.white70 : ZK.muted)),
              Text(rupiah(cart.total),
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900, color: dark ? Colors.white : ZK.slate900)),
            ],
          ),
          SizedBox(height: gapMd),
          SizedBox(
            height: btnH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: billMode ? simpan : split),
                const SizedBox(width: 8),
                Expanded(child: billMode ? split : simpan),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: empty ? null : onCheckout,
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                    child: FittedBox(
                      child: Text(billMode ? 'Bayar' : 'Bayar Semua',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tombol sekunder vertikal (ikon di atas label) di baris aksi keranjang.
  Widget _sideBtn(IconData icon, String label, VoidCallback? onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
            foregroundColor: ZK.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            side: const BorderSide(color: ZK.brand200),
            shape: const RoundedRectangleBorder(borderRadius: r12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            FittedBox(
                child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          ],
        ),
      );

  Widget _sumRow(String label, String value, bool dark, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: dark ? Colors.white60 : ZK.slate500)),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color ?? (dark ? Colors.white : ZK.slate900))),
          ],
        ),
      );
}

// DiskonBox dilipat jadi "+ Tambah potongan"; terbuka bila potongan sudah ada.
class _DiskonFold extends StatefulWidget {
  final int subtotal, diskon;
  final ValueChanged<int> onChanged;
  const _DiskonFold({required this.subtotal, required this.diskon, required this.onChanged});
  @override
  State<_DiskonFold> createState() => _DiskonFoldState();
}

class _DiskonFoldState extends State<_DiskonFold> {
  late bool _open = widget.diskon > 0;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: _open || widget.diskon > 0
            ? Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: DiskonBox(
                    subtotal: widget.subtotal, diskon: widget.diskon, onChanged: widget.onChanged),
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 36,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _open = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah potongan', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                        foregroundColor: ZK.accent, padding: const EdgeInsets.symmetric(horizontal: 4)),
                  ),
                ),
              ),
      );
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQty;
  const _CartRow({required this.item, required this.onQty});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Tablet: baris dipadatkan (bukan dilebarkan) supaya lebih banyak produk
    // kelihatan sekaligus di panel keranjang tanpa perlu scroll terus.
    final tablet = isTablet(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tablet ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumb(url: item.produk.foto, size: tablet ? 34 : 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produk.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.slate900)),
                if (item.modifierText != null)
                  Text(item.modifierText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: ZK.primary)),
                Text(
                    '${rupiah(item.unit)}${item.produk.satuan != null ? ' / ${item.produk.satuan}' : ''}',
                    style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate500)),
                SizedBox(height: tablet ? 4 : 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QtyStepper(
                        deleteAtOne: true,
                        qty: item.qty,
                        onMinus: () => onQty(item.qty - 1),
                        onPlus: () => onQty(item.qty + 1)),
                    Text(rupiah(item.total),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : ZK.slate900)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
