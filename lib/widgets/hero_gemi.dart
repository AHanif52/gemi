import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Angka besar di atas layar (tokens .hero): label kecil, nilai fs-6, delta opsional.
class HeroGemi extends StatelessWidget {
  const HeroGemi({super.key, required this.label, required this.nilai, this.delta});

  final String label, nilai;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodySmall?.copyWith(color: g.ink2)),
          const SizedBox(height: 4),
          Text(nilai, style: t.displaySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          if (delta != null) ...[
            const SizedBox(height: 8),
            Text(delta!, style: t.bodySmall?.copyWith(color: g.ink2)),
          ],
        ],
      ),
    );
  }
}
