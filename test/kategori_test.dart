import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/app/format.dart';
import 'package:gemi/budget/budget_controller.dart';
import 'package:gemi/budget/budget_repository.dart';
import 'package:gemi/kantong/kantong_controller.dart';
import 'package:gemi/kantong/kantong_model.dart';
import 'package:gemi/kantong/kantong_repository.dart';
import 'package:gemi/kategori/kategori_controller.dart';
import 'package:gemi/kategori/kategori_model.dart';
import 'package:gemi/kategori/kategori_repository.dart';
import 'package:gemi/transaksi/transaksi_controller.dart';
import 'package:gemi/transaksi/transaksi_model.dart';
import 'package:gemi/transaksi/transaksi_repository.dart';

void main() {
  late GemiDatabase db;
  late KategoriController kategori;
  late TransaksiController transaksi;
  late BudgetController budget;
  late BudgetRepository budgetRepo;
  late int bca;
  final ini = bulanIni();

  setUp(() async {
    db = GemiDatabase(NativeDatabase.memory());
    final repo = KategoriRepository(db);
    kategori = KategoriController(repo);
    final kantong = KantongController(KantongRepository(db));
    transaksi = TransaksiController(TransaksiRepository(db), repo, kantong);
    budgetRepo = BudgetRepository(db);
    budget = BudgetController(budgetRepo);
    kategori.addListener(transaksi.muat);
    transaksi.addListener(budget.muat);
    await kantong.tambah(nama: 'BCA', jenis: JenisKantong.bank, saldoAwal: 0);
    bca = kantong.daftar.single.id;
    await kategori.muat();
    await transaksi.muat();
  });
  // Listener muat() berjalan async setelah tiap perubahan; tunggu selesai sebelum DB ditutup.
  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await db.close();
  });

  Future<void> tunggu(String bulan) async {
    while (budget.data(bulan) == null) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('tambah kustom di urutan terakhir; ubah nama & warna', () async {
    await kategori.tambah(nama: ' Kopi ', jenis: JenisKategori.expense, warna: 3);
    final k = kategori.semua(JenisKategori.expense).last;
    expect(k.name, 'Kopi');
    expect(k.isDefault, isFalse);
    expect(k.sortOrder, greaterThan(9));
    await kategori.ubah(k.id, nama: 'Ngopi', warna: 4);
    expect(kategori.semua(JenisKategori.expense).last.name, 'Ngopi');
    await expectLater(() => kategori.tambah(nama: ' ', jenis: JenisKategori.income, warna: 0), throwsArgumentError);
  });

  test('sembunyikan bawaan: hilang dari form transaksi dan Ubah budget; tampilkan lagi mengembalikan', () async {
    final makan = kategori.semua(JenisKategori.expense).first;
    await kategori.sembunyikan(makan.id, true);
    await Future<void>.delayed(Duration.zero);
    expect(transaksi.kategori(JenisTransaksi.expense).map((k) => k.name), isNot(contains('Makan')));
    expect((await budgetRepo.kategoriKeluar()).map((k) => k.name), isNot(contains('Makan')));
    expect(kategori.aktif(JenisKategori.expense), 6);

    await kategori.sembunyikan(makan.id, false);
    await Future<void>.delayed(Duration.zero);
    expect(transaksi.kategori(JenisTransaksi.expense).first.name, 'Makan');
  });

  test('budget kategori tersembunyi: tetap dihitung kalau terpakai, tidak disalin ke bulan depan', () async {
    final makan = kategori.semua(JenisKategori.expense)[0];
    final transport = kategori.semua(JenisKategori.expense)[1];
    await budget.simpan(ini, {makan.id: 100000, transport.id: 50000});
    await transaksi.tambah(jenis: JenisTransaksi.expense, nominal: 20000, kantongId: bca, kategoriId: makan.id, tanggal: '$ini-03');
    await kategori.sembunyikan(makan.id, true);
    await kategori.sembunyikan(transport.id, true);
    await budget.muat();
    await tunggu(ini);

    final d = budget.data(ini)!;
    expect(d.baris.map((b) => b.kategori.name), ['Makan']); // Transport tersembunyi & belum terpakai: hilang
    expect(d.totalPakai, 20000);

    final depan = geserBulan(ini, 1);
    await tunggu(depan);
    expect(budget.data(depan)!.totalPlafon, 0);
  });

  test('hapus kustom: ditolak kalau dipakai, bawaan tidak bisa dihapus', () async {
    await kategori.tambah(nama: 'Kopi', jenis: JenisKategori.expense, warna: 0);
    final kopi = kategori.semua(JenisKategori.expense).last;
    await transaksi.tambah(jenis: JenisTransaksi.expense, nominal: 5000, kantongId: bca, kategoriId: kopi.id, tanggal: '$ini-01');
    await expectLater(() => kategori.hapus(kopi), throwsStateError);
    await expectLater(() => kategori.hapus(kategori.semua(JenisKategori.expense).first), throwsArgumentError);

    await kategori.tambah(nama: 'Sekali', jenis: JenisKategori.income, warna: 1);
    final sekali = kategori.semua(JenisKategori.income).last;
    await kategori.hapus(sekali);
    expect(kategori.semua(JenisKategori.income).map((k) => k.name), isNot(contains('Sekali')));
  });
}
