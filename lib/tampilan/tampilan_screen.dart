import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import 'tampilan_controller.dart';

/// /pengaturan/tampilan — pilih mode terang/gelap/ikuti sistem.
class TampilanScreen extends StatelessWidget {
  const TampilanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final t = Theme.of(context).textTheme;
    final c = context.watch<TampilanController>();
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('‹ Pengaturan'),
        ),
        leadingWidth: 130,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text('Tampilan', style: t.titleLarge),
          ),
          Text(
            'Warna mengikuti design token yang sama di kedua mode.',
            style: t.bodySmall?.copyWith(color: g.ink2),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final (m, label) in [
                (ThemeMode.system, 'Ikuti sistem'),
                (ThemeMode.light, 'Terang'),
                (ThemeMode.dark, 'Gelap'),
              ])
                ChoiceChip(
                  key: Key('tampilan.${m.name}'),
                  label: Text(label),
                  selected: c.mode == m,
                  onSelected: (_) => c.setMode(m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
