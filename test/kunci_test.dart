import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/kunci/kunci_controller.dart';
import 'package:gemi/kunci/kunci_repository.dart';
import 'package:gemi/pengaturan/pengaturan_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PIN: hash bukan PIN, cocok/salah, 5 salah -> jeda, ubah PIN reset', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = GemiDatabase(NativeDatabase.memory());
    final prefs = PengaturanRepository(db);
    final repo = KunciRepository(prefs, storage: const FlutterSecureStorage());
    final c = KunciController(repo);
    await c.muat();
    expect(c.aktif, false);
    expect(c.terkunci, false);

    await c.aturPin('1234');
    expect(c.aktif, true);
    expect(await const FlutterSecureStorage().read(key: 'pin_hash'), isNot(contains('1234')));
    expect(await prefs.baca('kunci.aktif'), '1');

    c.kunci();
    expect(c.terkunci, true);
    expect(await c.buka('0000'), false);
    expect(c.gagal, 1);
    for (var i = 0; i < 4; i++) {
      await c.buka('0000');
    }
    expect(c.gagal, 5);
    expect(c.sisaJeda, isNotNull);
    expect(c.sisaJeda!.inSeconds, inInclusiveRange(28, 30));
    // Selama jeda, PIN benar pun ditolak.
    expect(await c.buka('1234'), false);
    expect(c.terkunci, true);

    // Jeda tersimpan di settings supaya restart tidak menghapusnya.
    final c2 = KunciController(repo);
    await c2.muat();
    expect(c2.terkunci, true);
    expect(c2.sisaJeda, isNotNull);

    // Ubah PIN dari pengaturan mereset hitungan; PIN lama tidak berlaku.
    await c.aturPin('9876');
    expect(c.sisaJeda, isNull);
    expect(await c.buka('1234'), false);
    expect(await c.buka('9876'), true);
    expect(c.terkunci, false);

    await c.matikan();
    expect(c.aktif, false);
    expect(await repo.adaPin, false);
    await db.close();
  });
}
