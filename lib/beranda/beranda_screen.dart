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
          // Mata ikut prototype: di samping angka hero. Kalau belum ada budget
          // hero tidak punya angka, mata naik ke app bar supaya tetap ada.
          if (budget != null && !budget.adaBudget) const TombolMata(),
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 88), // 88: ruang FAB
        children: [
          if (budget != null && !budget.adaBudget)
            _HeroTanpaBudget(bulan: bulan)
          else if (budget != null)
            HeroGemi(
              label: 'Sisa budget ${fmtBulan(bulan, pendek: true)}',
              nilai: 'Rp ${fmtRupiah(budget.sisa)}',
              mata: true,
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

/// Hero saat belum ada plafon sama sekali: sebut langkah berikutnya, ketuk ke /budget.
class _HeroTanpaBudget extends StatelessWidget {
  const _HeroTanpaBudget({required this.bulan});
  final String bulan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    return InkWell(
      key: const Key('budget.atur'),
      onTap: () => Navigator.pushNamed(context, '/budget'),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget ${fmtBulan(bulan, pendek: true)}',
              style: t.bodySmall?.copyWith(color: g.ink2),
            ),
            const SizedBox(height: 4),
            Text('Belum diatur', style: t.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tetapkan plafon per kategori supaya sisa budget tampil di sini ›',
              style: t.bodySmall?.copyWith(color: g.ink2),
            ),
          ],
        ),
      ),
    );
  }
}
