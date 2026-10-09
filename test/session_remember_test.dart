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

  test('tidak dicentang menghapus sesi lama yang sebelumnya diingat', () async {
    await Session.save('lama', user, persist: true);
    await Session.save('baru', user, persist: false);
    killApp();
    await Session.restore();
    expect(Session.token, isNull);
  });
}
