import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../backup/backup_controller.dart';
import '../pengingat/pengingat_controller.dart';
import '../tampilan/tampilan_controller.dart';
import '../kategori/kategori_controller.dart';
import '../kategori/kategori_model.dart';
import '../widgets/baris_gemi.dart';

/// /pengaturan — daftar tautan. Pengingat, kunci, backup, tampilan menyusul di 1.0.
class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final k = context.watch<KategoriController>();
    final b = context.watch<BackupController>();
    final p = context.watch<PengingatController>();
    final tm = context.watch<TampilanController>();
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('‹ Beranda'),
        ),
        leadingWidth: 110,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              'Pengaturan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          BarisTautan(
            key: const Key('pengaturan.kategori'),
            label: 'Kategori',
            sub:
                '${k.aktif(JenisKategori.expense)} pengeluaran · ${k.aktif(JenisKategori.income)} pemasukan',
            onTap: () => Navigator.pushNamed(context, '/pengaturan/kategori'),
          ),
          BarisTautan(
            key: const Key('pengaturan.backup'),
            label: 'Backup & restore',
            sub: b.keterangan,
            onTap: () => Navigator.pushNamed(context, '/pengaturan/backup'),
            tanpaGarisAtas: true,
          ),
          BarisTautan(
            key: const Key('pengaturan.pengingat'),
            label: 'Pengingat harian',
            sub: p.keterangan,
            onTap: () => Navigator.pushNamed(context, '/pengaturan/pengingat'),
            tanpaGarisAtas: true,
          ),
          for (final (nama, key) in [('Kunci aplikasi', 'kunci')])
            Opacity(
              opacity: .5,
              child: BarisTautan(
                key: Key('pengaturan.$key'),
                label: nama,
                sub: 'Menyusul',
                onTap: () {},
                tanpaGarisAtas: true,
              ),
            ),
          BarisTautan(
            key: const Key('pengaturan.tampilan'),
            label: 'Tampilan',
            sub: tm.keterangan,
            onTap: () => Navigator.pushNamed(context, '/pengaturan/tampilan'),
            tanpaGarisAtas: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Gemi. Tanpa internet, tanpa akun, data di HP ini.',
            style: TextStyle(fontSize: 12, color: g.ink2),
          ),
        ],
      ),
    );
  }
}
