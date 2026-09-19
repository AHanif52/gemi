import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Baris buku kas: judul + sub di kiri, nominal tabular di kanan (tokens .row).
class BarisGemi extends StatelessWidget {
  const BarisGemi({super.key, required this.judul, this.sub, required this.nominal, this.warnaNominal, this.onTap});

  final String judul;
  final String? sub;
  final String nominal;
  final Color? warnaNominal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: t.bodyMedium),
                  if (sub != null) Text(sub!, style: t.bodySmall?.copyWith(color: context.gemi.ink2)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              nominal,
              style: t.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()], color: warnaNominal),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris yang membuka layar lain (tokens .link-row): label, nilai, chevron.
class BarisTautan extends StatelessWidget {
  const BarisTautan({super.key, required this.label, this.nilai, this.ikon = '›', required this.onTap});

  final String label;
  final String? nilai;
  final String ikon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: g.rule))),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            if (nilai != null) Text(nilai!, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: 12),
            Text(ikon, style: TextStyle(color: g.ink3)),
          ],
        ),
      ),
    );
  }
}
