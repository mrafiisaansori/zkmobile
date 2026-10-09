import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zkkasir/core/network/api_client.dart';

// "Ingat saya": login lalu app ditutup (memori hilang) lalu dibuka lagi (restore).
void main() {
  const user = {'id': 1, 'nama': 'Kasir', 'username': 'kasir', 'role': 'kasir'};

  // Meniru app ditutup: semua state memori hilang, hanya SharedPreferences tersisa.
  void killApp() {
    Session.token = null;
    Session.user = null;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('dicentang: sesi bertahan setelah app dibuka lagi', () async {
    await Session.save('tok-1', user, persist: true);
    killApp();
    await Session.restore();
    expect(Session.token, 'tok-1');
    expect(Session.user?.username, 'kasir');
  });

  test('tidak dicentang: sesi jalan selama app terbuka, hilang setelah dibuka lagi', () async {
    await Session.save('tok-2', user, persist: false);
    expect(Session.token, 'tok-2'); // tetap login selama app terbuka
    killApp();
    await Session.restore();
    expect(Session.token, isNull);
    expect(Session.user, isNull);
  });

  test('form login pertama kali: tercentang, username kosong', () async {
    final p = await Session.loginPrefs();
    expect(p.$1, isTrue);
    expect(p.$2, '');
  });

  test('dicentang: pilihan & username terakhir diingat untuk form login', () async {
    await Session.save('tok', user, persist: true);
    await Session.clear(); // logout
    final p = await Session.loginPrefs();
    expect(p.$1, isTrue);
    expect(p.$2, 'kasir');
  });

  test('tidak dicentang: pilihan diingat, username tidak', () async {
    await Session.save('tok', user, persist: true);
    await Session.save('tok', user, persist: false);
    final p = await Session.loginPrefs();
    expect(p.$1, isFalse);
    expect(p.$2, '');
  });

  test('password tidak pernah disimpan', () async {
    await Session.save('tok', user, persist: true);
    final sp = await SharedPreferences.getInstance();
    for (final k in sp.getKeys()) {
      expect(k.toLowerCase().contains('pass'), isFalse, reason: 'kunci $k');
    }
  });

  test('tidak dicentang menghapus sesi lama yang sebelumnya diingat', () async {
    await Session.save('lama', user, persist: true);
    await Session.save('baru', user, persist: false);
    killApp();
    await Session.restore();
    expect(Session.token, isNull);
  });
}
