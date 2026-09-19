import 'package:flutter/material.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../budget/budget_model.dart';

/// Satu kategori di halaman budget (tokens .budget): nama, terpakai / plafon, bar, catatan.
/// Bar abu-abu normal, kuning ≥ 80%, merah lewat (FR-08).
class BarBudget extends StatelessWidget {
  const BarBudget(this.b, {super.key, required this.hariSisa});
  final BarisBudget b;
  final int hariSisa;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final t = Theme.of(context).textTheme;
    final warna = b.lewat ? g.over : b.hampir ? g.near : g.ink2;
    final catatan = b.plafon == 0
        ? null
        : b.lewat
            ? 'Lewat ${fmtRupiah(b.pakai - b.plafon)}'
            : b.pakai == 0
                ? 'Belum terpakai'
                : b.pakai * 100 >= b.plafon * 70 && hariSisa > 0
                    ? 'Sisa ${fmtRupiah(b.sisa)} · sekitar ${fmtRupiah(_perHari(b.sisa, hariSisa))} per hari'
                    : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(b.kategori.name)),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: fmtRupiah(b.pakai), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
                  TextSpan(text: b.plafon == 0 ? ' · tanpa budget' : ' / ${fmtRupiah(b.plafon)}'),
                ]),
                style: t.bodySmall?.copyWith(color: g.ink2, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          if (b.plafon > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: b.porsi, minHeight: 6, backgroundColor: g.rule, color: warna),
            ),
          ],
          if (catatan != null) ...[
            const SizedBox(height: 4),
            Text(catatan, style: TextStyle(fontSize: 12, color: b.lewat ? g.over : g.ink2)),
          ],
        ],
      ),
    );
  }
}

/// Sisa dibagi hari, dibulatkan ke ribuan supaya enak dibaca.
int _perHari(int sisa, int hari) => (sisa / (hari == 0 ? 1 : hari) / 1000).round() * 1000;
