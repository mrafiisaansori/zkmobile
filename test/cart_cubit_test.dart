import 'package:flutter_test/flutter_test.dart';
import 'package:zkkasir/features/pos/cubit/cart_cubit.dart';
import 'package:zkkasir/features/pos/cubit/cart_state.dart';
import 'package:zkkasir/shared/models/models.dart';

// Regresi: menambah produk yang sama dulu memutasi qty in-place, sehingga
// state baru dianggap sama (Equatable) dan total di bar keranjang tidak berubah.
void main() {
  final kopi = Produk.raw(1, 'Kopi', 5000, 10);

  test('tambah produk yang sama menaikkan qty & total, dan state benar-benar berubah', () async {
    final cubit = CartCubit();
    final emitted = <CartState>[];
    final sub = cubit.stream.listen(emitted.add);

    cubit.addItem(kopi);
    cubit.addItem(kopi);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, 2, reason: 'tiap tambah harus memicu rebuild');
    expect(cubit.state.items.single.qty, 2);
    expect(cubit.state.total, 10000);
    await sub.cancel();
  });

  test('updateQty memicu state baru dan tetap jalan dengan referensi item lama', () async {
    final cubit = CartCubit()..addItem(kopi);
    final lama = cubit.state.items.single;
    final emitted = <CartState>[];
    final sub = cubit.stream.listen(emitted.add);

    cubit.updateQty(lama, 3);
    cubit.updateQty(lama, 4); // referensi sudah usang setelah update pertama
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, 2);
    expect(cubit.state.items.single.qty, 4);
    expect(cubit.state.items.single.lineId, lama.lineId);
    await sub.cancel();
  });
}
