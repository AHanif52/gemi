import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../budget/budget_controller.dart';
import '../kantong/kantong_controller.dart';
import '../transaksi/transaksi_controller.dart';
import '../transaksi/transaksi_list_screen.dart';
import '../widgets/baris_gemi.dart';
import '../widgets/hero_gemi.dart';
import '../widgets/nominal.dart';

/// /beranda — sisa budget bulan ini, baris kantong, catatan hari ini dan kemarin.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kantong = context.watch<KantongController>();
    final transaksi = context.watch<TransaksiController>();
    final bulan = bulanIni();
    final budget = context.watch<BudgetController>().data(bulan);
    final sisaHari = hariSisa(bulan);
    final kemarin = ymd(DateTime.now().subtract(const Duration(days: 1)));
    final terbaru = transaksi.daftar
        .where((b) => b.t.date.compareTo(kemarin) >= 0)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemi'),
        actions: [
          const TombolMata(),
          Text(
            fmtTanggalPanjang(DateTime.now()),
            style: TextStyle(fontSize: 13, color: context.gemi.ink2),
          ),
          IconButton(
            key: const Key('pengaturan.buka'),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.pushNamed(context, '/pengaturan'),
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          if (budget != null && budget.adaBudget)
            HeroGemi(
              label: 'Sisa budget ${fmtBulan(bulan, pendek: true)}',
              nilai: 'Rp ${fmtRupiah(budget.sisa)}',
              delta: budget.sisa < 0
                  ? 'Lewat ${fmtRupiah(-budget.sisa)}'
                  : sisaHari > 0
                  ? '$sisaHari hari lagi · sekitar ${fmtRupiah((budget.sisa / sisaHari / 1000).round() * 1000)} per hari'
                  : 'Hari terakhir bulan ini',
            ),
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
