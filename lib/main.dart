import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/database.dart';
import 'app/shell.dart';
import 'app/theme.dart';
import 'kantong/kantong_controller.dart';
import 'kantong/kantong_form_screen.dart';
import 'kantong/kantong_repository.dart';
import 'kantong/kantong_screen.dart';
import 'kategori/kategori_repository.dart';
import 'transaksi/transaksi_controller.dart';
import 'transaksi/transaksi_form_screen.dart';
import 'transaksi/transaksi_repository.dart';

void main() {
  final db = GemiDatabase();
  final kantong = KantongController(KantongRepository(db))..muat();
  final transaksi = TransaksiController(TransaksiRepository(db), KategoriRepository(db), kantong)..muat();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: kantong),
        ChangeNotifierProvider.value(value: transaksi),
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
        '/mulai': (_) => const KantongFormScreen(pertama: true),
        '/kantong': (_) => const KantongScreen(),
        '/kantong/baru': (_) => const KantongFormScreen(),
      },
      home: const _Gerbang(),
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
