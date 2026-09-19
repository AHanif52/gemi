// Test alur end-to-end di memori: seluruh app dirakit lewat rakitApp() dengan DB
// in-memory, lalu dikendalikan lewat Key nama aksi (BRD: Nama aksi tetap).
// Tanpa emulator, tanpa platform channel.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/app/format.dart';
import 'package:gemi/main.dart';
import 'package:gemi/pengingat/penjadwal.dart';

/// Penjadwal palsu: mencatat jadwal terakhir supaya aturan FR-17 bisa diperiksa.
class PenjadwalPalsu implements Penjadwal {
  DateTime? jadwal;
  int batalDipanggil = 0;
  @override
  Future<void> siapkan() async {}
  @override
  Future<void> batal() async {
    batalDipanggil++;
    jadwal = null;
  }

  @override
  Future<void> jadwalHarian(DateTime pertama, {required String judul, required String isi}) async => jadwal = pertama;
}

late GemiDatabase db;
late PenjadwalPalsu penjadwal;

Future<void> bukaApp(WidgetTester t) async {
  // Font test (Ahem) jauh lebih lebar dari font asli; lebar logis 540 supaya tata letak tidak overflow.
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  FlutterSecureStorage.setMockInitialValues({});
  db = GemiDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await db.close();
  });
  penjadwal = PenjadwalPalsu();
  await t.pumpWidget(await rakitApp(db, penjadwal: penjadwal, storageKunci: const FlutterSecureStorage()));
  await t.pumpAndSettle();
}

/// Toast (SnackBar) tidak hilang sendiri di test; toast dengan tombol (Batalkan)
/// bahkan tidak hilang setelah waktu dimajukan, jadi tutup paksa supaya tidak
/// menutup tombol bawah (Lanjut/Simpan).
Future<void> tutupToast(WidgetTester t) async {
  await t.pump(const Duration(seconds: 5));
  final scaffold = find.byType(Scaffold);
  if (scaffold.evaluate().isNotEmpty) {
    ScaffoldMessenger.of(t.element(scaffold.first)).clearSnackBars();
  }
  await t.pumpAndSettle();
}

/// Jalankan [aksi] dengan waktu nyata sambil terus menggambar frame (untuk kerja di isolate,
/// mis. hash PIN Argon2id yang tidak maju di waktu palsu test).
Future<void> nyata(WidgetTester t, Future<void> Function() aksi, {int ms = 2000}) => t.runAsync(() async {
      await aksi();
      for (var i = 0; i < ms ~/ 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await t.pump();
      }
    });

/// Tombol kembali kustom di app bar ('‹ Pengaturan', '‹ Beranda', 'Batal').
Future<void> kembali(WidgetTester t, String label) async {
  await t.tap(find.text(label));
  await t.pumpAndSettle();
}

Future<void> ketuk(WidgetTester t, String key) async {
  await t.ensureVisible(find.byKey(Key(key)));
  await t.tap(find.byKey(Key(key)));
  await t.pumpAndSettle();
}

Future<void> ketik(WidgetTester t, String key, String teks) async {
  await t.enterText(find.byKey(Key(key)), teks);
  await t.pumpAndSettle();
}

Future<void> keypad(WidgetTester t, String prefix, String digit) async {
  for (final d in digit.split('')) {
    await t.tap(find.byKey(Key('$prefix.$d')));
    await t.pump();
  }
  await t.pumpAndSettle();
}

/// Layar pertama: buat kantong BCA, saldo 1.000.000.
Future<void> mulai(WidgetTester t, {int saldo = 1000000}) async {
  expect(find.text('Mulai mencatat'), findsOneWidget);
  await ketik(t, 'kantong.nama', 'BCA');
  await ketik(t, 'kantong.saldo', '$saldo');
  await ketuk(t, 'mulai.simpan');
  expect(find.text('Semua kantong'), findsOneWidget);
  await tutupToast(t);
}

/// Tambah pengeluaran lewat keypad, kategori Makan (id 1), simpan.
Future<void> tambahPengeluaran(WidgetTester t, String digit, {int kategoriId = 1, String catatan = ''}) async {
  await tutupToast(t);
  await ketuk(t, 'transaksi.tambah');
  await keypad(t, 'transaksi.keypad', digit);
  await ketuk(t, 'transaksi.lanjut');
  await ketuk(t, 'transaksi.kategori.$kategoriId');
  if (catatan.isNotEmpty) await ketik(t, 'transaksi.catatan', catatan);
  await ketuk(t, 'transaksi.simpan');
}

void main() {
  testWidgets('pertama kali buka: buat kantong, Beranda tampil total kantong', (t) async {
    await bukaApp(t);
    await mulai(t);
    expect(find.text('1.000.000'), findsOneWidget);
    expect(find.byKey(const Key('nav.transaksi')), findsOneWidget);
  });

  testWidgets('tambah pengeluaran 3 ketukan: saldo turun, muncul di Beranda, Batalkan mengembalikan', (t) async {
    await bukaApp(t);
    await mulai(t);
    await tambahPengeluaran(t, '32000', catatan: 'Nasi padang');

    expect(find.text('Nasi padang'), findsOneWidget);
    expect(find.text('968.000'), findsOneWidget); // 1.000.000 - 32.000
    expect(find.text('Transaksi tersimpan'), findsOneWidget);

    await t.tap(find.text('Batalkan'));
    await t.pumpAndSettle();
    expect(find.text('Nasi padang'), findsNothing);
    expect(find.text('1.000.000'), findsOneWidget);
  });

  testWidgets('transfer antar kantong: satu entri, saldo pindah, tidak dihitung pengeluaran', (t) async {
    await bukaApp(t);
    await mulai(t);
    // kantong kedua: GoPay saldo 0
    await ketuk(t, 'kantong.lihat');
    await ketuk(t, 'kantong.tambah');
    await ketik(t, 'kantong.nama', 'GoPay');
    await ketuk(t, 'kantong.jenis.emoney');
    await ketuk(t, 'kantong.simpan');
    expect(find.text('GoPay'), findsOneWidget);
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();

    await tutupToast(t);
    await ketuk(t, 'transaksi.tambah');
    await ketuk(t, 'transaksi.jenis.transfer');
    await keypad(t, 'transaksi.keypad', '100000');
    await ketuk(t, 'transaksi.kantongTujuan');
    await t.tap(find.text('GoPay').last);
    await t.pumpAndSettle();
    await ketuk(t, 'transaksi.simpan');

    expect(find.text('Ke GoPay'), findsOneWidget);
    expect(find.text('1.000.000'), findsOneWidget); // total semua kantong tetap
    await ketuk(t, 'kantong.lihat');
    expect(find.text('900.000'), findsOneWidget);
    expect(find.text('100.000'), findsOneWidget);
  });

  testWidgets('budget: ubah plafon, sisa budget tampil di form, bar di halaman Budget, hero Beranda', (t) async {
    await bukaApp(t);
    await mulai(t);
    await ketuk(t, 'nav.budget');
    expect(find.text('Belum ada budget'), findsOneWidget);
    await ketuk(t, 'budget.ubah');
    await ketik(t, 'budget.plafon.1', '100000'); // Makan
    expect(find.byKey(const Key('budget.total')), findsOneWidget);
    await ketuk(t, 'budget.simpan');
    expect(find.text('Terpakai dari 100.000'), findsOneWidget);

    await ketuk(t, 'nav.beranda');
    await tutupToast(t);
    await ketuk(t, 'transaksi.tambah');
    await keypad(t, 'transaksi.keypad', '85000');
    await ketuk(t, 'transaksi.lanjut');
    expect(find.text('Sisa budget Makan 15.000 setelah ini'), findsOneWidget); // FR-07
    await ketuk(t, 'transaksi.simpan');

    expect(find.text('Sisa budget ${_bulanIni()}'), findsOneWidget);
    expect(find.text('Rp 15.000'), findsOneWidget);
    await ketuk(t, 'nav.budget');
    expect(find.textContaining('Sisa 15.000'), findsWidgets); // ≥ 80%: catatan sisa per hari
  });

  testWidgets('ubah dan hapus transaksi dengan konfirmasi', (t) async {
    await bukaApp(t);
    await mulai(t);
    await tambahPengeluaran(t, '32000', catatan: 'Kopi');
    await tutupToast(t);
    await t.tap(find.text('Kopi'));
    await t.pumpAndSettle();
    expect(find.text('Ubah transaksi'), findsOneWidget);
    await ketik(t, 'transaksi.nominal', '25000');
    await ketuk(t, 'transaksi.simpanUbah');
    expect(find.text('975.000'), findsOneWidget);
    await tutupToast(t);

    await t.tap(find.text('Kopi'));
    await t.pumpAndSettle();
    await ketuk(t, 'transaksi.hapus');
    expect(find.text('Hapus transaksi ini?'), findsOneWidget);
    await ketuk(t, 'transaksi.hapus.ya');
    expect(find.text('Kopi'), findsNothing);
    expect(find.text('1.000.000'), findsOneWidget);
  });

  testWidgets('laporan: tiga periode terbuka, angka mingguan & bulanan sesuai', (t) async {
    await bukaApp(t);
    await mulai(t);
    await tambahPengeluaran(t, '52000');
    await ketuk(t, 'nav.laporan');
    expect(find.text('Rp 52.000'), findsOneWidget); // Keluar minggu ini
    await ketuk(t, 'laporan.bulan');
    expect(find.text('Rp −52.000'), findsOneWidget); // tabungan = 0 − 52.000
    expect(find.text('Komposisi pengeluaran'), findsOneWidget);
    await ketuk(t, 'laporan.hari');
    expect(find.text('Keluar hari ini'), findsOneWidget);
  });

  testWidgets('kategori kustom muncul di form; sembunyikan bawaan menghilangkannya', (t) async {
    await bukaApp(t);
    await mulai(t);
    await ketuk(t, 'pengaturan.buka');
    await ketuk(t, 'pengaturan.kategori');
    await ketuk(t, 'kategori.tambah');
    await ketik(t, 'kategori.nama', 'Ngopi');
    await ketuk(t, 'kategori.warna.2');
    await ketuk(t, 'kategori.simpan');
    expect(find.text('Ngopi'), findsOneWidget);
    await tutupToast(t);
    // sembunyikan Makan (id 1)
    await ketuk(t, 'kategori.1');
    await ketuk(t, 'kategori.sekunder');
    expect(find.text('Disembunyikan'), findsOneWidget);
    await kembali(t, '‹ Pengaturan');
    await kembali(t, '‹ Beranda');
    await tutupToast(t);

    await ketuk(t, 'transaksi.tambah');
    await keypad(t, 'transaksi.keypad', '1000');
    await ketuk(t, 'transaksi.lanjut');
    expect(find.text('Ngopi'), findsOneWidget);
    expect(find.text('Makan'), findsNothing);
  });

  testWidgets('sembunyikan nominal: semua nominal jadi ••••••, diingat', (t) async {
    await bukaApp(t);
    await mulai(t);
    await ketuk(t, 'nominal.mata');
    expect(find.text('1.000.000'), findsNothing);
    expect(find.textContaining('••••••'), findsWidgets);
    await ketuk(t, 'nav.transaksi');
    await ketuk(t, 'nominal.mata');
    await ketuk(t, 'nav.beranda');
    expect(find.text('1.000.000'), findsOneWidget);
  });

  testWidgets('pengingat: mencatat hari ini menggeser jadwal ke besok; mematikan membatalkan', (t) async {
    await bukaApp(t);
    await mulai(t);
    final besok = DateTime.now().add(const Duration(days: 1));
    await tambahPengeluaran(t, '1000');
    expect(penjadwal.jadwal, isNotNull);
    expect(penjadwal.jadwal!.day, besok.day);
    expect(penjadwal.jadwal!.hour, 21);

    await ketuk(t, 'pengaturan.buka');
    await ketuk(t, 'pengaturan.pengingat');
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(penjadwal.jadwal, isNull);
    await kembali(t, '‹ Pengaturan');
    expect(find.descendant(of: find.byKey(const Key('pengaturan.pengingat')), matching: find.text('Mati')), findsOneWidget);
  });

  testWidgets('kunci aplikasi: buat PIN, coba layar kunci, PIN salah ditolak, PIN benar membuka', (t) async {
    await bukaApp(t);
    await mulai(t);
    await ketuk(t, 'pengaturan.buka');
    await ketuk(t, 'pengaturan.kunci');
    await t.tap(find.descendant(of: find.byKey(const Key('kunci.aktif')), matching: find.byType(Switch)));
    await t.pumpAndSettle();
    expect(find.text('Buat PIN'), findsOneWidget);
    await keypad(t, 'kunci.keypad', '1234');
    expect(find.text('Ulangi PIN'), findsOneWidget);
    // Hash Argon2id berjalan di isolate: butuh waktu nyata, bukan waktu palsu test.
    await nyata(t, () => keypad(t, 'kunci.keypad', '1234'));
    await tutupToast(t);
    expect(find.byKey(const Key('kunci.coba')), findsOneWidget);

    await ketuk(t, 'kunci.coba');
    expect(find.text('Masukkan PIN'), findsOneWidget);
    await nyata(t, () => keypad(t, 'kunci.keypad', '0000'));
    await tutupToast(t);
    expect(find.text('Masukkan PIN'), findsOneWidget); // masih terkunci
    await nyata(t, () => keypad(t, 'kunci.keypad', '1234'));
    await tutupToast(t);
    expect(find.text('Masukkan PIN'), findsNothing);
  });
  testWidgets('cari transaksi: kata menyaring daftar, tanpa hasil tampil pesan kosong', (t) async {
    await bukaApp(t);
    await mulai(t);
    await tambahPengeluaran(t, '32000', catatan: 'Nasi padang');
    await tutupToast(t);
    // Kedua: kategori default = Makan (terakhir dipakai), langsung catatan.
    await ketuk(t, 'transaksi.tambah');
    await keypad(t, 'transaksi.keypad', '15000');
    await ketuk(t, 'transaksi.lanjut');
    await ketik(t, 'transaksi.catatan', 'Kopi');
    await ketuk(t, 'transaksi.simpan');
    await tutupToast(t);
    await ketuk(t, 'nav.transaksi');
    await ketuk(t, 'transaksi.cari');
    expect(find.text('Ketik kata atau pilih rentang tanggal.'), findsOneWidget);
    await ketik(t, 'transaksi.cari.kata', 'PADANG');
    expect(find.text('Nasi padang'), findsOneWidget);
    expect(find.text('Kopi'), findsNothing);
    await ketik(t, 'transaksi.cari.kata', 'zzz');
    expect(find.text('Tidak ada yang cocok'), findsOneWidget);
  });

  testWidgets('hari awal minggu: ganti ke Minggu menggeser rentang laporan mingguan', (t) async {
    await bukaApp(t);
    await mulai(t);
    await ketuk(t, 'nav.laporan');
    final now = DateTime.now();
    expect(find.text(fmtRentangMinggu(awalMinggu(now))), findsOneWidget);
    await ketuk(t, 'nav.beranda');
    await ketuk(t, 'pengaturan.buka');
    await ketuk(t, 'pengaturan.tampilan');
    await ketuk(t, 'tampilan.awalMinggu.7');
    expect(find.byKey(const Key('tampilan.layarAman')), findsOneWidget);
    await kembali(t, '‹ Pengaturan');
    await kembali(t, '‹ Beranda');
    await ketuk(t, 'nav.laporan');
    expect(find.text(fmtRentangMinggu(awalMinggu(now, hari: DateTime.sunday))), findsOneWidget);
  });

}

String _bulanIni() {
  const b = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  return b[DateTime.now().month - 1];
}
