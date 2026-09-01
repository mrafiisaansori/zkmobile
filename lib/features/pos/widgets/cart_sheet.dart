import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../models/cart_item.dart';
import 'sheet_common.dart';

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
            action: cart.items.isEmpty
                ? null
                : TextButton(
                    // Kosongkan isi keranjang tanpa membuang konteks bill/member —
                    // CartCubit tidak punya method "clear items saja", jadi
                    // dibongkar lewat remove() per baris + setDiskon(0).
                    onPressed: () {
                      final cubit = context.read<CartCubit>();
                      for (final it in List<CartItem>.from(cart.items)) {
                        cubit.remove(it);
                      }
                      cubit.setDiskon(0);
                    },
                    child: const Text('Kosongkan',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: ZK.rose)),
                  ),
          ),
          Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
          if (isPro) _memberRow(context, cart, dark),
          Expanded(
            child: cart.items.isEmpty
                ? const EmptyState(
                    title: 'Keranjang masih kosong',
                    description: 'Pilih produk dari grid untuk mulai transaksi.')
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: dark ? ZK.lineDark : const Color(0xFFF1F5F9)),
                    itemBuilder: (_, i) => _CartRow(
                      item: cart.items[i],
                      onQty: (q) {
                        final r = context.read<CartCubit>().updateQty(cart.items[i], q);
                        if (!r.ok) toastError(context, r.message!);
                      },
                    ),
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
                              color: dark ? Colors.white : const Color(0xFF1E293B))),
                      Text(cart.member == null ? 'Pilih member/customer' : 'Ganti member',
                          style: TextStyle(
                              fontSize: 11, color: dark ? Colors.white60 : ZK.slate500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: dark ? Colors.white38 : ZK.slate400),
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
    final btnH = tablet ? 42.0 : 44.0;
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
          SizedBox(height: gapSm),
          DiskonBox(
              subtotal: cart.subtotal,
              diskon: cart.diskon,
              onChanged: context.read<CartCubit>().setDiskon),
          SizedBox(height: gapMd),
          Divider(height: 1, color: dark ? ZK.lineDark : const Color(0xFFF1F5F9)),
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
            height: tablet ? 46 : 48,
            width: double.infinity,
            child: FilledButton(
              onPressed: cart.items.isEmpty ? null : onCheckout,
              style: FilledButton.styleFrom(
                  backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
              child: Text(billMode ? 'Bayar' : 'Bayar Semua',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          SizedBox(height: gapSm),
          // Split Bill + (Simpan Bill / Simpan+Batalkan) sebaris di tablet
          // supaya cuma makan satu baris tinggi, bukan tumpuk dua-tiga baris.
          if (tablet)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: btnH,
                    child: OutlinedButton.icon(
                      onPressed: cart.items.isEmpty ? null : onSplitBill,
                      icon: const Icon(Icons.call_split, size: 16),
                      label: const Text('Split Bill', style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.primary,
                          side: const BorderSide(color: ZK.brand200),
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ),
                if (!billMode) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: btnH,
                      child: OutlinedButton.icon(
                        onPressed: cart.items.isEmpty ? null : onSaveBill,
                        icon: const Icon(Icons.assignment_outlined, size: 16),
                        label: const Text('Simpan Bill', style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: ZK.primary,
                            side: const BorderSide(color: ZK.brand200),
                            shape: const RoundedRectangleBorder(borderRadius: r12)),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            SizedBox(
              height: btnH,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: cart.items.isEmpty ? null : onSplitBill,
                icon: const Icon(Icons.call_split, size: 17),
                label: const Text('Split Bill', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: ZK.primary,
                    side: const BorderSide(color: ZK.brand200),
                    shape: const RoundedRectangleBorder(borderRadius: r12)),
              ),
            ),
          SizedBox(height: gapSm),
          if (billMode)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: btnH,
                    child: OutlinedButton.icon(
                      onPressed: cart.items.isEmpty ? null : onUpdateBill,
                      icon: const Icon(Icons.save_outlined, size: 17),
                      label: const Text('Simpan'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.primary,
                          side: const BorderSide(color: ZK.brand200),
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: btnH,
                    child: OutlinedButton.icon(
                      onPressed: onCancelBill,
                      icon: const Icon(Icons.delete_outline, size: 17),
                      label: const Text('Batalkan'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ZK.rose,
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape: const RoundedRectangleBorder(borderRadius: r12)),
                    ),
                  ),
                ),
              ],
            )
          else if (!tablet)
            SizedBox(
              height: btnH,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: cart.items.isEmpty ? null : onSaveBill,
                icon: const Icon(Icons.assignment_outlined, size: 17),
                label: const Text('Simpan Bill', style: TextStyle(fontWeight: FontWeight.w700)),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(item.produk.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : ZK.slate900)),
                    ),
                    InkWell(
                      onTap: () => onQty(0),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            size: 18, color: dark ? Colors.white38 : ZK.slate400),
                      ),
                    ),
                  ],
                ),
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
