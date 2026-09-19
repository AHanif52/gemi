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
          const SizedBox(height: 32),
          Text('Minggu dimulai hari', style: t.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Dipakai laporan mingguan dan grafik per hari.',
            style: t.bodySmall?.copyWith(color: g.ink2),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final (h, label) in [
                (DateTime.monday, 'Senin'),
                (DateTime.sunday, 'Minggu'),
              ])
                ChoiceChip(
                  key: Key('tampilan.awalMinggu.$h'),
                  label: Text(label),
                  selected: c.awalMinggu == h,
                  onSelected: (_) => c.setAwalMinggu(h),
                ),
            ],
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            key: const Key('tampilan.layarAman'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Blokir screenshot'),
            subtitle: const Text(
              'Layar tidak bisa di-screenshot dan tampil hitam di daftar aplikasi terbaru.',
            ),
            value: c.layarAman,
            onChanged: c.setLayarAman,
          ),
        ],
      ),
    );
  }
}
