import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/database.dart' show Kategori;
import '../app/theme.dart';
import '../widgets/baris_gemi.dart';
import 'kategori_controller.dart';
import 'kategori_form_screen.dart';
import 'kategori_model.dart';

/// /pengaturan/kategori — daftar per jenis; ketuk baris untuk ubah/sembunyikan/hapus.
class KategoriScreen extends StatefulWidget {
  const KategoriScreen({super.key});

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen> {
  var _jenis = JenisKategori.expense;

  void _buka([Kategori? k]) => Navigator.push(
    context,
    MaterialPageRoute(
      settings: RouteSettings(
        name: k == null
            ? '/pengaturan/kategori/baru'
            : '/pengaturan/kategori/ubah',
      ),
      builder: (_) => KategoriFormScreen(kategori: k, jenisAwal: _jenis),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    final c = context.watch<KategoriController>();
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
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              'Kategori',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: g.rule)),
            ),
            child: Row(
              children: [
                for (final j in const [JenisKategori.expense, JenisKategori.income])
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: InkWell(
                      key: Key('kategori.jenis.${j.name}'),
                      onTap: () => setState(() => _jenis = j),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: j == _jenis ? ink : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          j == JenisKategori.expense
                              ? 'Pengeluaran'
                              : 'Pemasukan',
                          style: TextStyle(
                            color: j == _jenis ? ink : g.ink2,
                            fontWeight: j == _jenis ? FontWeight.w500 : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final k in c.semua(_jenis))
            Opacity(
              opacity: k.isHidden ? .6 : 1,
              child: BarisGemi(
                key: Key('kategori.${k.id}'),
                judul: k.name,
                titik: g.kategori(k.color),
                sub: k.isHidden
                    ? 'Disembunyikan'
                    : k.isDefault
                    ? 'Bawaan'
                    : 'Kustom',
                nominal: '›',
                warnaNominal: g.ink3,
                onTap: () => _buka(k),
              ),
            ),
          BarisTautan(
            key: const Key('kategori.tambah'),
            label: 'Tambah kategori',
            ikon: '+',
            onTap: _buka,
          ),
        ],
      ),
    );
  }
}
