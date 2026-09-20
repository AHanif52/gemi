import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../transaksi/transaksi_controller.dart';
import 'pengingat_controller.dart';

/// /pengaturan/pengingat — aktif/mati + jam, dengan contoh notifikasi (FR-17).
class PengingatScreen extends StatelessWidget {
  const PengingatScreen({super.key});

  bool _adaHariIni(BuildContext context) => context
      .read<TransaksiController>()
      .daftar
      .any((b) => b.t.date == hariIni());

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final t = Theme.of(context).textTheme;
    final c = context.watch<PengingatController>();
    final surface2 = g.surface2;
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
            child: Text('Pengingat harian', style: t.titleLarge),
          ),
          Text(
            'Gemi mengingatkan hanya kalau hari itu belum ada transaksi. Kalau sudah mencatat, pengingat batal sendiri. Tanpa internet.',
            style: t.bodySmall?.copyWith(color: g.ink2),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const Key('pengingat.aktif'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Aktif'),
            value: c.aktif,
            activeThumbColor: Colors.white,
            activeTrackColor: g.income,
            onChanged: (v) =>
                c.setAktif(v, adaTransaksiHariIni: _adaHariIni(context)),
          ),
          Opacity(
            opacity: c.aktif ? 1 : .4,
            child: ListTile(
              key: const Key('pengingat.jam'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Jam'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.jam.replaceAll(':', '.'),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              enabled: c.aktif,
              onTap: () async {
                final awal = TimeOfDay(
                  hour: int.parse(c.jam.substring(0, 2)),
                  minute: int.parse(c.jam.substring(3, 5)),
                );
                final pilih = await showTimePicker(
                  context: context,
                  initialTime: awal,
                );
                if (pilih == null || !context.mounted) return;
                await c.setJam(
                  '${pilih.hour.toString().padLeft(2, '0')}:${pilih.minute.toString().padLeft(2, '0')}',
                  adaTransaksiHariIni: _adaHariIni(context),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Contoh notifikasi',
            style: t.bodySmall?.copyWith(
              color: g.ink2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Opacity(
            opacity: c.aktif ? 1 : .4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Belum ada transaksi hari ini. Ada pengeluaran yang belum dicatat?',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
