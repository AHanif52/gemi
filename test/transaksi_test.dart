import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/app/format.dart';
import 'package:gemi/kantong/kantong_controller.dart';
import 'package:gemi/kantong/kantong_model.dart';
import 'package:gemi/kantong/kantong_repository.dart';
import 'package:gemi/kategori/kategori_repository.dart';
import 'package:gemi/laporan/csv_bulanan.dart';
import 'package:gemi/transaksi/transaksi_cari_screen.dart';
import 'package:gemi/transaksi/transaksi_controller.dart';
import 'package:gemi/transaksi/transaksi_model.dart';
import 'package:gemi/transaksi/transaksi_repository.dart';

void main() {
  late GemiDatabase db;
  late KantongController kantong;
  late TransaksiController c;
  late int bca, gopay;

  setUp(() async {
    db = GemiDatabase(NativeDatabase.memory());
    kantong = KantongController(KantongRepository(db));
    c = TransaksiController(TransaksiRepository(db), KategoriRepository(db), kantong);
    await kantong.tambah(nama: 'BCA', jenis: JenisKantong.bank, saldoAwal: 1000000);
    await kantong.tambah(nama: 'GoPay', jenis: JenisKantong.emoney, saldoAwal: 50000);
    bca = kantong.daftar[0].id;
    gopay = kantong.daftar[1].id;
    await c.muat();
  });
  tearDown(() => db.close());

  test('kategori bawaan ter-seed: 7 keluar, 3 masuk', () {
    expect(c.kategori(JenisTransaksi.expense).map((k) => k.name).first, 'Makan');
    expect(c.kategori(JenisTransaksi.expense), hasLength(7));
    expect(c.kategori(JenisTransaksi.income), hasLength(3));
  });

  test('pengeluaran, pemasukan, transfer mengubah saldo kantong; hapus mengembalikan', () async {
    final makan = c.kategoriDefault(JenisTransaksi.expense)!;
    final gaji = c.kategoriDefault(JenisTransaksi.income)!;
    final id = await c.tambah(jenis: JenisTransaksi.expense, nominal: 32000, kantongId: gopay, kategoriId: makan, tanggal: '2026-09-18', catatan: 'Nasi padang');
    await c.tambah(jenis: JenisTransaksi.income, nominal: 8500000, kantongId: bca, kategoriId: gaji, tanggal: '2026-09-01');
    await c.tambah(jenis: JenisTransaksi.transfer, nominal: 100000, kantongId: bca, kantongTujuanId: gopay, tanggal: '2026-09-17');

    expect(kantong.saldo(kantong.daftar[0]), 1000000 + 8500000 - 100000);
    expect(kantong.saldo(kantong.daftar[1]), 50000 - 32000 + 100000);
    expect(kantong.total, 9518000);

    // urut tanggal terbaru di atas; judul & sub sesuai prototipe
    expect(c.daftar.map((b) => b.t.date), ['2026-09-18', '2026-09-17', '2026-09-01']);
    expect(c.daftar[0].judul, 'Nasi padang');
    expect(c.daftar[0].sub, 'Makan · GoPay');
    expect(c.daftar[1].judul, 'Ke GoPay');
    expect(c.daftar[1].sub, 'BCA ke GoPay');
    expect(c.daftar[2].judul, 'Gaji');

    // default form = terakhir dipakai
    expect(c.kantongDefault(), bca);

    await c.hapus(id);
    expect(kantong.saldo(kantong.daftar[1]), 150000);
    expect(c.daftar, hasLength(2));
  });

  test('ubah transaksi: saldo dikoreksi dari nilai lama ke baru', () async {
    final makan = c.kategoriDefault(JenisTransaksi.expense)!;
    final transport = c.kategori(JenisTransaksi.expense)[1].id;
    final id = await c.tambah(jenis: JenisTransaksi.expense, nominal: 32000, kantongId: gopay, kategoriId: makan, tanggal: '2026-09-18');
    await c.ubah(id, jenis: JenisTransaksi.expense, nominal: 25000, kantongId: bca, kategoriId: transport, tanggal: '2026-09-17', catatan: ' Ojek ');

    expect(kantong.saldo(kantong.daftar[0]), 1000000 - 25000);
    expect(kantong.saldo(kantong.daftar[1]), 50000);
    expect(c.daftar.single.judul, 'Ojek');
    expect(c.daftar.single.sub, 'Transport · BCA');
    expect(c.daftar.single.t.date, '2026-09-17');
  });

  test('validasi: nominal 0, transfer ke kantong sama, tanpa kategori', () async {
    final makan = c.kategoriDefault(JenisTransaksi.expense)!;
    expect(() => c.tambah(jenis: JenisTransaksi.expense, nominal: 0, kantongId: bca, kategoriId: makan, tanggal: '2026-09-18'), throwsArgumentError);
    expect(() => c.tambah(jenis: JenisTransaksi.transfer, nominal: 1000, kantongId: bca, kantongTujuanId: bca, tanggal: '2026-09-18'), throwsArgumentError);
    expect(() => c.tambah(jenis: JenisTransaksi.expense, nominal: 1000, kantongId: bca, tanggal: '2026-09-18'), throwsArgumentError);
  });

  test('penyesuaian saldo: selisih jadi transaksi Lainnya, bisa dibatalkan, tanpa selisih = null (FR-20)', () async {
    final k = kantong.daftar[0]; // BCA, saldo 1.000.000
    final turun = await c.sesuaikanSaldo(kantong: k, saldoRiil: 940000);
    expect(turun, isNotNull);
    expect(kantong.saldo(k), 940000);
    final b = c.daftar.firstWhere((b) => b.t.id == turun);
    expect(b.t.type, JenisTransaksi.expense);
    expect(b.t.amount, 60000);
    expect(b.kategori?.name, 'Lainnya');
    expect(b.t.note, 'Penyesuaian saldo');

    final naik = await c.sesuaikanSaldo(kantong: k, saldoRiil: 1200000);
    expect(c.daftar.firstWhere((b) => b.t.id == naik).t.type, JenisTransaksi.income);
    expect(kantong.saldo(k), 1200000);

    expect(await c.sesuaikanSaldo(kantong: k, saldoRiil: 1200000), isNull);

    await c.hapus(naik!);
    expect(kantong.saldo(k), 940000);
  });

  test('cari: kata cocok catatan/kategori/kantong tanpa peduli huruf; rentang tanggal inklusif (FR-04)', () async {
    final makan = c.kategoriDefault(JenisTransaksi.expense)!;
    final gaji = c.kategoriDefault(JenisTransaksi.income)!;
    await c.tambah(jenis: JenisTransaksi.expense, nominal: 32000, kantongId: gopay, kategoriId: makan, tanggal: '2026-09-18', catatan: 'Nasi Padang');
    await c.tambah(jenis: JenisTransaksi.income, nominal: 8500000, kantongId: bca, kategoriId: gaji, tanggal: '2026-09-01');
    await c.tambah(jenis: JenisTransaksi.transfer, nominal: 100000, kantongId: bca, kantongTujuanId: gopay, tanggal: '2026-08-31');

    List<String> tgl(List<TransaksiBaris> l) => l.map((b) => b.t.date).toList();
    expect(tgl(cariTransaksi(c.daftar, kata: 'padang')), ['2026-09-18']); // catatan
    expect(tgl(cariTransaksi(c.daftar, kata: 'gaji')), ['2026-09-01']); // kategori
    expect(tgl(cariTransaksi(c.daftar, kata: 'gopay')), ['2026-09-18', '2026-08-31']); // kantong + kantong tujuan
    expect(tgl(cariTransaksi(c.daftar, dari: '2026-09-01', sampai: '2026-09-18')), ['2026-09-18', '2026-09-01']);
    expect(tgl(cariTransaksi(c.daftar, kata: 'bca', sampai: '2026-08-31')), ['2026-08-31']);
    expect(cariTransaksi(c.daftar, kata: 'zzz'), isEmpty);
  });

  test('csv bulanan: hanya bulan itu, urut naik, koma & kutip di-escape (FR-15)', () async {
    final makan = c.kategoriDefault(JenisTransaksi.expense)!;
    await c.tambah(jenis: JenisTransaksi.expense, nominal: 32000, kantongId: gopay, kategoriId: makan, tanggal: '2026-09-18', catatan: 'Nasi, "padang"');
    await c.tambah(jenis: JenisTransaksi.transfer, nominal: 100000, kantongId: bca, kantongTujuanId: gopay, tanggal: '2026-09-02');
    await c.tambah(jenis: JenisTransaksi.expense, nominal: 5000, kantongId: bca, kategoriId: makan, tanggal: '2026-08-31');

    expect(
      csvBulanan(c.daftar, '2026-09'),
      'tanggal,jenis,kategori,kantong,kantong_tujuan,nominal,catatan\r\n'
      '2026-09-02,Transfer,,BCA,GoPay,100000,\r\n'
      '2026-09-18,Pengeluaran,Makan,GoPay,,32000,"Nasi, ""padang"""\r\n',
    );
  });

  test('format tanggal', () {
    final now = DateTime(2026, 9, 18);
    expect(fmtTanggal('2026-09-18', sekarang: now), 'Hari ini');
    expect(fmtTanggal('2026-09-17', sekarang: now), 'Kemarin');
    expect(fmtTanggal('2026-09-14', sekarang: now), 'Senin, 14 Sep');
    expect(ymd(now), '2026-09-18');
  });
}
