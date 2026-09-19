import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../widgets/bar_budget.dart';
import '../widgets/hero_gemi.dart';
import 'budget_controller.dart';
import 'budget_ubah_screen.dart';

/// /budget — terpakai vs plafon per kategori, navigasi bulan (FR-08, FR-13).
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  var _bulan = bulanIni();

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final d = context.watch<BudgetController>().data(_bulan);
    final sisaHari = hariSisa(_bulan);
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('budget.bulanLalu'),
                onPressed: () =>
                    setState(() => _bulan = geserBulan(_bulan, -1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  fmtBulan(_bulan),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                key: const Key('budget.bulanDepan'),
                onPressed: () => setState(() => _bulan = geserBulan(_bulan, 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (d == null)
            const SizedBox(height: 120)
          else if (!d.adaBudget && d.baris.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Text(
                    'Belum ada budget',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tetapkan plafon per kategori supaya sisa terlihat saat mencatat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: g.ink2),
                  ),
                ],
              ),
            )
          else ...[
            HeroGemi(
              label: d.adaBudget
                  ? 'Terpakai dari ${fmtRupiah(d.totalPlafon)}'
                  : 'Terpakai',
              nilai: 'Rp ${fmtRupiah(d.totalPakai)}',
              delta: !d.adaBudget
                  ? 'Belum ada plafon'
                  : d.sisa < 0
                  ? 'Lewat ${fmtRupiah(-d.sisa)}'
                  : sisaHari > 0
                  ? 'Sisa ${fmtRupiah(d.sisa)} untuk $sisaHari hari'
                  : 'Sisa ${fmtRupiah(d.sisa)}',
            ),
            for (final b in d.baris)
              BarBudget(
                b,
                key: Key('budget.${b.kategori.id}'),
                hariSisa: sisaHari,
              ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('budget.ubah'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: '/budget/ubah'),
                builder: (_) => BudgetUbahScreen(bulan: _bulan),
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: g.rule),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Ubah budget'),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}
