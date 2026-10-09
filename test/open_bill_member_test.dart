import 'package:flutter_test/flutter_test.dart';
import 'package:zkkasir/features/pos/data/pos_repository.dart';
import 'package:zkkasir/shared/models/models.dart';

void main() {
  test('OpenBill membaca object member, null bila tanpa member', () {
    final withMember = OpenBill.fromJson({
      'ID': 1,
      'MEMBER_ID': 7,
      'member': {'ID': 7, 'NAMA': 'Rafi', 'NO_HP': '0812'},
    });
    expect(withMember.member?.id, 7);
    expect(withMember.member?.nama, 'Rafi');
    expect(OpenBill.fromJson({'ID': 2, 'MEMBER_ID': null, 'member': null}).member, isNull);
  });

  test('body create/edit bill selalu membawa member_id (angka atau null)', () {
    final repo = PosRepository();
    expect(repo.billBody('Budi', '04', '', const [], 7)['member_id'], 7);
    final lepas = repo.billBody('Budi', '04', '', const [], null);
    expect(lepas.containsKey('member_id'), isTrue);
    expect(lepas['member_id'], isNull);
  });

  test('body bayar bill tidak lagi mengirim member_id', () {
    final body = PosRepository().payBillBody(idJenisBayar: 1, bayar: 1000);
    expect(body.containsKey('member_id'), isFalse);
  });
}
