import 'package:flutter_test/flutter_test.dart';
import 'package:zkkasir/core/cubit/form_submit_cubit.dart';
import 'package:zkkasir/core/cubit/list_cubit.dart';

// Regresi: state awal `const ListState()` jadi ListState<Never>, sehingga
// load() gagal TypeError dan semua daftar admin tampil kosong.
void main() {
  test('ListCubit menyimpan item hasil fetch', () async {
    final cubit = ListCubit<String>(fetchPage: ({search, page = 1}) async => ['a', 'b']);
    await cubit.load();
    expect(cubit.state.status, ListStatus.ready);
    expect(cubit.state.items, ['a', 'b']);
  });

  test('FormSubmitCubit menyimpan hasil submit', () async {
    final cubit = FormSubmitCubit<int>();
    expect(await cubit.submit(() async => 7), 7);
    expect(cubit.state.result, 7);
  });
}
