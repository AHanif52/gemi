import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'nominal.dart';

/// Angka besar di atas layar (tokens .hero): label kecil, nilai fs-6, delta opsional.
/// [mata] menaruh tombol sembunyikan nominal di samping nilai (Beranda, FR-21).
class HeroGemi extends StatelessWidget {
  const HeroGemi({
    super.key,
    required this.label,
    required this.nilai,
    this.delta,
    this.mata = false,
  });

  final String label, nilai;
  final String? delta;
  final bool mata;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    final rp = nilai.startsWith('Rp ');
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodySmall?.copyWith(color: g.ink2)),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Nominal(
                  rp ? nilai.substring(3) : nilai,
                  awalan: rp ? 'Rp ' : '',
                  style: t.displaySmall,
                ),
              ),
              if (mata)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: TombolMata(),
                ),
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: 8),
            Text(delta!, style: t.bodySmall?.copyWith(color: g.ink2)),
          ],
        ],
      ),
    );
  }
}
