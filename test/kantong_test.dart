import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/app/format.dart';
import 'package:gemi/kantong/kantong_controller.dart';
import 'package:gemi/kantong/kantong_model.dart';
import 'package:gemi/kantong/kantong_repository.dart';

void main() {
  late GemiDatabase db;
  late KantongController c;

  setUp(() {
    db = GemiDatabase(NativeDatabase.memory());
    c = KantongController(KantongRepository(db));
  });
  tearDown(() => db.close());

  test('kosong saat pertama, total = jumlah saldo awal setelah tambah', () async {
    await c.muat();
    expect(c.kosong, isTrue);

    await c.tambah(nama: 'BCA', jenis: JenisKantong.bank, saldoAwal: 4250000);
    await c.tambah(nama: ' GoPay ', jenis: JenisKantong.emoney, saldoAwal: 85000);

    expect(c.daftar.map((k) => k.name), ['BCA', 'GoPay']);
    expect(c.daftar.last.type, JenisKantong.emoney);
    expect(c.total, 4335000);
  });

  test('nama kosong ditolak', () async {
    await c.muat();
    expect(() => c.tambah(nama: '  ', jenis: JenisKantong.cash, saldoAwal: 0), throwsArgumentError);
  });

  test('format rupiah bolak-balik', () {
    expect(fmtRupiah(5605000), '5.605.000');
    expect(fmtRupiah(0), '0');
    expect(fmtRupiah(-87000), '−87.000');
    expect(parseRupiah('5.605.000'), 5605000);
    expect(parseRupiah(''), 0);
  });
}
