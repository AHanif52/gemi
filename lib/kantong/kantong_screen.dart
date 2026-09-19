import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../widgets/baris_gemi.dart';
import '../widgets/hero_gemi.dart';
import 'kantong_controller.dart';

/// /kantong — daftar kantong + total (FR-18).
class KantongScreen extends StatelessWidget {
  const KantongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<KantongController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kantong')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          HeroGemi(label: 'Semua kantong', nilai: 'Rp ${fmtRupiah(c.total)}'),
          for (final k in c.daftar)
            BarisGemi(key: Key('kantong.${k.id}'), judul: k.name, sub: k.type.label, nominal: fmtRupiah(c.saldo(k))),
          BarisTautan(
            key: const Key('kantong.tambah'),
            label: 'Tambah kantong',
            ikon: '+',
            onTap: () => Navigator.pushNamed(context, '/kantong/baru'),
          ),
        ],
      ),
    );
  }
}
