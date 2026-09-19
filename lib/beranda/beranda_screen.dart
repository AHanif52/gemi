import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../kantong/kantong_controller.dart';
import '../widgets/baris_gemi.dart';

/// /beranda — tab utama. Baru baris kantong; sisa budget dan catatan hari ini menyusul.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<KantongController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Gemi')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          BarisTautan(
            key: const Key('kantong.lihat'),
            label: 'Semua kantong',
            nilai: fmtRupiah(c.total),
            onTap: () => Navigator.pushNamed(context, '/kantong'),
          ),
        ],
      ),
    );
  }
}
