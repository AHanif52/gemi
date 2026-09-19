import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'nominal.dart';

/// Baris buku kas: judul + sub di kiri, nominal tabular di kanan (tokens .row).
class BarisGemi extends StatelessWidget {
  const BarisGemi({
    super.key,
    required this.judul,
    this.sub,
    this.titik,
    required this.nominal,
    this.warnaNominal,
    this.onTap,
  });

  final String judul;
  final String? sub;
  final Color? titik; // dot warna kategori di depan judul
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
                  Row(
                    children: [
                      if (titik != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: titik,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(child: Text(judul, style: t.bodyMedium)),
                    ],
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: t.bodySmall?.copyWith(color: context.gemi.ink2),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Nominal(
              nominal,
              style: t.bodyMedium?.copyWith(color: warnaNominal),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris yang membuka layar lain (tokens .link-row): label, nilai, chevron.
class BarisTautan extends StatelessWidget {
  const BarisTautan({
    super.key,
    required this.label,
    this.sub,
    this.nilai,
    this.ikon = '›',
    required this.onTap,
    this.tanpaGarisAtas = false,
  });

  final String label;
  final String? sub;
  final String? nilai;
  final bool tanpaGarisAtas; // baris beruntun: garis atas dari baris sebelumnya sudah cukup
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
        decoration: BoxDecoration(
          border: Border(
            top: tanpaGarisAtas ? BorderSide.none : BorderSide(color: g.rule),
            bottom: BorderSide(color: g.rule),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  if (sub != null)
                    Text(sub!, style: TextStyle(fontSize: 13, color: g.ink2)),
                ],
              ),
            ),
            if (nilai != null) Nominal(nilai!),
            const SizedBox(width: 12),
            Text(ikon, style: TextStyle(color: g.ink3)),
          ],
        ),
      ),
    );
  }
}
