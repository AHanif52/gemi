import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Layar kosong (design system `.empty`): judul + langkah berikutnya, rata tengah.
/// Dipakai di tengah body kalau layar benar-benar kosong, atau di dalam daftar
/// kalau ada header di atasnya.
class KosongGemi extends StatelessWidget {
  const KosongGemi({super.key, required this.judul, required this.langkah});

  final String judul;
  final String langkah;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(judul, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            langkah,
            textAlign: TextAlign.center,
            style: TextStyle(color: g.ink2),
          ),
        ],
      ),
    );
  }
}
