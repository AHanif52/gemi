import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/app/format.dart';
import 'package:gemi/budget/budget_controller.dart';
import 'package:gemi/budget/budget_repository.dart';
import 'package:gemi/kantong/kantong_controller.dart';
import 'package:gemi/kantong/kantong_model.dart';
import 'package:gemi/kantong/kantong_repository.dart';
import 'package:gemi/kategori/kategori_repository.dart';
import 'package:gemi/transaksi/transaksi_controller.dart';
import 'package:gemi/transaksi/transaksi_model.dart';
import 'package:gemi/transaksi/transaksi_repository.dart';

void main() {
  late GemiDatabase db;
  late TransaksiController transaksi;
  late BudgetController budget;
  late int bca, makan, transport;
  final ini = bulanIni(), lalu = geserBulan(bulanIni(), -1);

  setUp(() async {
    db = GemiDatabase(NativeDatabase.memory());
    final kantong = KantongController(KantongRepository(db));
    transaksi = TransaksiController(TransaksiRepository(db), KategoriRepository(db), kantong);
    budget = BudgetController(BudgetRepository(db));
    transaksi.addListener(budget.muat);
    await kantong.tambah(nama: 'BCA', jenis: JenisKantong.bank, saldoAwal: 0);
    bca = kantong.daftar.single.id;
    await transaksi.muat();
    makan = transaksi.kategori(JenisTransaksi.expense)[0].id;
    transport = transaksi.kategori(JenisTransaksi.expense)[1].id;
  });
  tearDown(() => db.close());

  /// data() memuat async; tunggu sampai terisi.
  Future<void> tunggu(String bulan) async {
    while (budget.data(bulan) == null) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('terpakai per kategori, tanda hampir dan lewat, sisa setelah nominal (FR-07/08)', () async {
    await budget.simpan(ini, {makan: 100000, transport: 50000});
    await transaksi.tambah(jenis: JenisTransaksi.expense, nominal: 85000, kantongId: bca, kategoriId: makan, tanggal: '$ini-05');
    await transaksi.tambah(jenis: JenisTransaksi.expense, nominal: 60000, kantongId: bca, kategoriId: transport, tanggal: '$ini-06');
    await tunggu(ini);

    final d = budget.data(ini)!;
    expect(d.totalPlafon, 150000);
    expect(d.totalPakai, 145000);
    final m = d.baris.firstWhere((b) => b.kategori.id == makan);
    final t = d.baris.firstWhere((b) => b.kategori.id == transport);
    expect(m.hampir, isTrue);
    expect(m.lewat, isFalse);
    expect(t.lewat, isTrue);
    expect(budget.sisaSetelah(kategoriId: makan, nominal: 20000, bulan: ini), -5000);
    expect(budget.sisaSetelah(kategoriId: transaksi.kategori(JenisTransaksi.expense)[2].id, nominal: 1, bulan: ini), isNull);
  });

  test('bulan baru menyalin budget bulan lalu; bulan lampau kosong tetap kosong (FR-06)', () async {
    await budget.simpan(lalu, {makan: 100000});
    await tunggu(ini);
    expect(budget.data(ini)!.totalPlafon, 100000);

    final duaLalu = geserBulan(ini, -2);
    await tunggu(duaLalu);
    expect(budget.data(duaLalu)!.baris, isEmpty);
  });

  test('pengeluaran tanpa budget tetap tampil sebagai baris tanpa plafon', () async {
    await transaksi.tambah(jenis: JenisTransaksi.expense, nominal: 5000, kantongId: bca, kategoriId: makan, tanggal: '$ini-01');
    await tunggu(ini);
    final d = budget.data(ini)!;
    expect(d.adaBudget, isFalse);
    expect(d.baris.single.plafon, 0);
    expect(d.baris.single.pakai, 5000);
  });

  test('helper bulan', () {
    expect(fmtBulan('2026-09'), 'September 2026');
    expect(geserBulan('2026-01', -1), '2025-12');
    expect(hariSisa('2026-09', sekarang: DateTime(2026, 9, 18)), 12);
    expect(hariSisa('2026-08', sekarang: DateTime(2026, 9, 18)), 0);
    expect(hariSisa('2026-10', sekarang: DateTime(2026, 9, 18)), 31);
  });
}
