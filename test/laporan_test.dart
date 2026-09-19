import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/app/format.dart';
import 'package:gemi/kantong/kantong_model.dart';
import 'package:gemi/laporan/laporan_repository.dart';
import 'package:gemi/transaksi/transaksi_model.dart';

void main() {
  late GemiDatabase db;
  late LaporanRepository repo;
  late int bca, makan, transport, gaji;

  setUp(() async {
    db = GemiDatabase(NativeDatabase.memory());
    repo = LaporanRepository(db);
    bca = await db.into(db.accounts).insert(AccountsCompanion.insert(name: 'BCA', type: JenisKantong.bank, initialBalance: 0));
    final kat = await db.select(db.categories).get();
    makan = kat.firstWhere((k) => k.name == 'Makan').id;
    transport = kat.firstWhere((k) => k.name == 'Transport').id;
    gaji = kat.firstWhere((k) => k.name == 'Gaji').id;
  });
  tearDown(() => db.close());

  Future<void> isi(JenisTransaksi j, int n, String tgl, {int? kat, int? ke}) => db.into(db.transactions).insert(TransactionsCompanion.insert(
      type: j, amount: n, accountId: bca, date: tgl, categoryId: Value(kat), toAccountId: Value(ke)));

  test('ringkasan: masuk/keluar, per hari, per kategori urut terbesar; transfer diabaikan', () async {
    await isi(JenisTransaksi.income, 8500000, '2026-09-01', kat: gaji);
    await isi(JenisTransaksi.expense, 32000, '2026-09-18', kat: makan);
    await isi(JenisTransaksi.expense, 30000, '2026-09-18', kat: makan);
    await isi(JenisTransaksi.expense, 70000, '2026-09-16', kat: transport);
    await isi(JenisTransaksi.transfer, 100000, '2026-09-17', ke: bca);
    await isi(JenisTransaksi.expense, 999, '2026-08-31', kat: makan); // di luar rentang

    final r = await repo.ringkasan('2026-09-01', '2026-09-30');
    expect(r.masuk, 8500000);
    expect(r.keluar, 132000);
    expect(r.selisih, 8368000);
    expect(r.keluarPerHari, {'2026-09-18': 62000, '2026-09-16': 70000});
    expect(r.keluarPerKategori.map((k) => k.kategori.name), ['Transport', 'Makan']);
    expect(r.keluarPerKategori[1].jumlah, 2);
  });

  test('NFR-05: laporan bulanan < 300 ms untuk 10.000 transaksi', () async {
    await db.batch((b) {
      for (var i = 0; i < 10000; i++) {
        final d = DateTime(2026, 1, 1).add(Duration(days: i % 270));
        b.insert(db.transactions, TransactionsCompanion.insert(
            type: i % 10 == 0 ? JenisTransaksi.income : JenisTransaksi.expense,
            amount: 1000 + i % 50000,
            accountId: bca,
            date: ymd(d),
            categoryId: Value(i % 10 == 0 ? gaji : (i % 2 == 0 ? makan : transport))));
      }
    });
    final sw = Stopwatch()..start();
    final r = await repo.ringkasan('2026-09-01', '2026-09-30');
    sw.stop();
    expect(r.keluar, greaterThan(0));
    expect(sw.elapsedMilliseconds, lessThan(300), reason: 'laporan bulanan ${sw.elapsedMilliseconds} ms');
  });

  test('helper minggu dan ringkas', () {
    expect(ymd(awalMinggu(DateTime(2026, 9, 18))), '2026-09-14'); // Jumat -> Senin
    expect(ymd(awalMinggu(DateTime(2026, 9, 14))), '2026-09-14'); // Senin tetap
    expect(fmtRentangMinggu(DateTime(2026, 9, 14)), '14 – 20 Sep');
    expect(fmtRentangMinggu(DateTime(2026, 9, 28)), '28 Sep – 4 Okt');
    expect(fmtRingkas(1240000), '1,2 jt');
    expect(fmtRingkas(1000000), '1 jt');
    expect(fmtRingkas(980000), '980 rb');
    expect(fmtRingkas(500), '500');
  });
}
