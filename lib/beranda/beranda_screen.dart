import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../kantong/kantong_controller.dart';
import '../transaksi/transaksi_controller.dart';
import '../transaksi/transaksi_list_screen.dart';
import '../widgets/baris_gemi.dart';

/// /beranda — baris kantong + catatan hari ini dan kemarin. Sisa budget menyusul (0.2).
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kantong = context.watch<KantongController>();
    final transaksi = context.watch<TransaksiController>();
    final kemarin = ymd(DateTime.now().subtract(const Duration(days: 1)));
    final terbaru = transaksi.daftar.where((b) => b.t.date.compareTo(kemarin) >= 0).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Gemi')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          BarisTautan(
            key: const Key('kantong.lihat'),
            label: 'Semua kantong',
            nilai: fmtRupiah(kantong.total),
            onTap: () => Navigator.pushNamed(context, '/kantong'),
          ),
          ...bukuKas(context, terbaru),
        ],
      ),
    );
  }
}
