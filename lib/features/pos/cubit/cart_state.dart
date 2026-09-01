import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';
import '../models/bill_context.dart';
import '../models/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final int diskon;
  final BillContext? bill;
  final Member? member;
  final VoucherPreview? voucher;

  const CartState({
    this.items = const [],
    this.diskon = 0,
    this.bill,
    this.member,
    this.voucher,
  });

  bool get billMode => bill != null;
  int get count => items.fold(0, (s, i) => s + i.qty);
  int get subtotal => items.fold(0, (s, i) => s + i.total);
  int get total {
    final t = subtotal - diskon - (voucher?.diskon ?? 0);
    return t < 0 ? 0 : t;
  }

  CartState copyWith({
    List<CartItem>? items,
    int? diskon,
    BillContext? bill,
    bool clearBill = false,
    Member? member,
    bool clearMember = false,
    VoucherPreview? voucher,
    bool clearVoucher = false,
  }) =>
      CartState(
        items: items ?? this.items,
        diskon: diskon ?? this.diskon,
        bill: clearBill ? null : (bill ?? this.bill),
        member: clearMember ? null : (member ?? this.member),
        voucher: clearVoucher ? null : (voucher ?? this.voucher),
      );

  // Equatable membandingkan identitas isi list secara referensial cukup di
  // sini karena CartCubit selalu emit list baru (bukan mutasi in-place) —
  // lihat catatan di cart_cubit.dart.
  @override
  List<Object?> get props => [items, diskon, bill, member, voucher];
}
