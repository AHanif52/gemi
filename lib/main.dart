import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/database.dart';
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
import 'transaksi/transaksi_controller.dart';
import 'transaksi/transaksi_form_screen.dart';
import 'transaksi/transaksi_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await GemiDatabase.buka();
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
  final backup = BackupController(
    BackupRepository(db),
    BackupService(),
    pengaturanRepo,
  )..muat();
  final kunci = KunciController(KunciRepository(pengaturanRepo))..muat();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: kantong),
        ChangeNotifierProvider.value(value: transaksi),
        ChangeNotifierProvider.value(value: budget),
        Provider.value(value: budgetRepo),
        ChangeNotifierProvider.value(value: laporan),
        ChangeNotifierProvider.value(value: kategori),
        ChangeNotifierProvider.value(value: backup),
        ChangeNotifierProvider.value(value: sembunyi),
        ChangeNotifierProvider.value(value: kunci),
      ],
      child: const GemiApp(),
    ),
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
        '/pengaturan/kunci': (_) => const KunciScreen(),
      },
      home: const _Gerbang(),
      // Kunci aplikasi (FR-16): layar PIN menutup semua route selama terkunci.
      builder: (_, child) => _GerbangKunci(child: child!),
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
