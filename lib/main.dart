import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'app/database.dart';
import 'app/format.dart';
import 'app/shell.dart';
import 'app/theme.dart';
import 'backup/backup_controller.dart';
import 'backup/backup_repository.dart';
import 'backup/backup_screen.dart';
import 'backup/backup_service.dart';
import 'budget/budget_controller.dart';
import 'budget/budget_repository.dart';
import 'kantong/kantong_controller.dart';
import 'kantong/kantong_form_screen.dart';
import 'kantong/kantong_repository.dart';
import 'kantong/kantong_screen.dart';
import 'kategori/kategori_controller.dart';
import 'kategori/kategori_repository.dart';
import 'kategori/kategori_screen.dart';
import 'kunci/kunci_controller.dart';
import 'kunci/kunci_repository.dart';
import 'kunci/kunci_screen.dart';
import 'kunci/pin_screen.dart';
import 'laporan/laporan_controller.dart';
import 'laporan/laporan_repository.dart';
import 'laporan/laporan_screen.dart';
import 'pengaturan/pengaturan_repository.dart';
import 'pengaturan/pengaturan_screen.dart';
import 'pengaturan/sembunyi_controller.dart';
import 'pengingat/pengingat_controller.dart';
import 'pengingat/penjadwal.dart';
import 'pengingat/pengingat_screen.dart';
import 'tampilan/tampilan_controller.dart';
import 'tampilan/tampilan_screen.dart';
import 'transaksi/transaksi_controller.dart';
import 'transaksi/transaksi_form_screen.dart';
import 'transaksi/transaksi_repository.dart';
import 'widgets/toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await rakitApp(await GemiDatabase.buka()));
}

/// Rakit seluruh pohon controller + provider di atas [db]. Test memanggil ini
/// dengan DB in-memory dan seam palsu (penjadwal, secure storage, biometrik).
Future<Widget> rakitApp(
  GemiDatabase db, {
  Penjadwal? penjadwal,
  FlutterSecureStorage? storageKunci,
  LocalAuthentication? auth,
}) async {
  final kantong = KantongController(KantongRepository(db))..muat();
  final kategoriRepo = KategoriRepository(db);
  final kategori = KategoriController(kategoriRepo)..muat();
  final transaksi = TransaksiController(
    TransaksiRepository(db),
    kategoriRepo,
    kantong,
  )..muat();
  // Kategori berubah (nama, warna, disembunyikan) -> form transaksi dan budget ikut.
  kategori.addListener(transaksi.muat);
  final budgetRepo = BudgetRepository(db);
  final budget = BudgetController(budgetRepo);
  // Terpakai per kategori berubah tiap transaksi berubah.
  transaksi.addListener(budget.muat);
  final laporan = LaporanController(LaporanRepository(db));
  transaksi.addListener(laporan.muat);
  final pengaturanRepo = PengaturanRepository(db);
  final sembunyi = SembunyiController(pengaturanRepo)..muat();
  final tampilan = TampilanController(pengaturanRepo)..muat();
  final pengingat = PengingatController(
    pengaturanRepo,
    penjadwal ?? PenjadwalNotifikasi(),
  );
  // FR-17: setiap transaksi berubah, jadwal pengingat dihitung ulang.
  bool adaHariIni() => transaksi.daftar.any((b) => b.t.date == hariIni());
  transaksi.addListener(
    () => pengingat.jadwalkan(adaTransaksiHariIni: adaHariIni()),
  );
  await pengingat.muat();
  final backup = BackupController(
    BackupRepository(db),
    BackupService(),
    pengaturanRepo,
  )..muat();
  final kunci = KunciController(
    KunciRepository(pengaturanRepo, storage: storageKunci),
    auth: auth,
  )..muat();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: kantong),
      ChangeNotifierProvider.value(value: transaksi),
      ChangeNotifierProvider.value(value: budget),
      Provider.value(value: budgetRepo),
      ChangeNotifierProvider.value(value: laporan),
      ChangeNotifierProvider.value(value: kategori),
      ChangeNotifierProvider.value(value: backup),
      ChangeNotifierProvider.value(value: sembunyi),
      ChangeNotifierProvider.value(value: tampilan),
      ChangeNotifierProvider.value(value: pengingat),
      ChangeNotifierProvider.value(value: kunci),
    ],
    child: const GemiApp(),
  );
}

class GemiApp extends StatelessWidget {
  const GemiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemi',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: context.watch<TampilanController>().mode,
      // Alamat tetap per layar (BRD: Prinsip UX). Tambah route di sini saat fitur baru masuk.
      routes: {
        '/beranda': (_) => const Shell(),
        '/transaksi': (_) => const Shell(tab: 1),
        '/transaksi/baru': (_) => const TransaksiFormScreen(),
        '/budget': (_) => const Shell(tab: 2),
        '/laporan': (_) => const Shell(tab: 3),
        '/laporan/hari': (_) => const Shell(tab: 3, periode: Periode.hari),
        '/laporan/minggu': (_) => const Shell(tab: 3, periode: Periode.minggu),
        '/laporan/bulan': (_) => const Shell(tab: 3, periode: Periode.bulan),
        '/mulai': (_) => const KantongFormScreen(pertama: true),
        '/kantong': (_) => const KantongScreen(),
        '/kantong/baru': (_) => const KantongFormScreen(),
        '/pengaturan': (_) => const PengaturanScreen(),
        '/pengaturan/kategori': (_) => const KategoriScreen(),
        '/pengaturan/backup': (_) => const BackupScreen(),
        '/pengaturan/pengingat': (_) => const PengingatScreen(),
        '/pengaturan/tampilan': (_) => const TampilanScreen(),
        '/pengaturan/kunci': (_) => const KunciScreen(),
      },
      home: const _Gerbang(),
      // Kunci aplikasi (FR-16): layar PIN menutup semua route selama terkunci.
      builder: (_, child) =>
          TutupToastSaatSentuh(child: _GerbangKunci(child: child!)),
    );
  }
}

/// Layar pertama: tunggu DB, lalu /mulai kalau belum ada kantong, selain itu Beranda.
class _Gerbang extends StatelessWidget {
  const _Gerbang();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<KantongController>();
    if (!c.siap) return const Scaffold();
    return c.kosong ? const KantongFormScreen(pertama: true) : const Shell();
  }
}

/// Tampilkan layar PIN di atas seluruh app selama terkunci; app di bawahnya
/// tetap hidup (state, route) supaya buka kunci kembali ke tempat semula.
class _GerbangKunci extends StatelessWidget {
  const _GerbangKunci({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final terkunci = context.select<KunciController, bool>(
      (c) => c.siap && c.terkunci,
    );
    return Stack(children: [child, if (terkunci) const PinScreen.buka()]);
  }
}
