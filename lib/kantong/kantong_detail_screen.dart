import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../transaksi/transaksi_controller.dart';
import '../transaksi/transaksi_list_screen.dart';
import '../widgets/hero_gemi.dart';
import '../widgets/kosong_gemi.dart';
import 'kantong_controller.dart';
import '../app/database.dart' show Kantong;

/// /kantong/{nama} — saldo satu kantong + transaksinya saja, termasuk transfer
/// masuk/keluar (FR-22). Pola daftar sama dengan /transaksi.
class KantongDetailScreen extends StatelessWidget {
  const KantongDetailScreen(this.kantong, {super.key});
  final Kantong kantong;

  @override
  Widget build(BuildContext context) {
    final saldo = context.watch<KantongController>().saldo(kantong);
    final daftar = context
        .watch<TransaksiController>()
        .daftar
        .where(
          (b) => b.t.accountId == kantong.id || b.t.toAccountId == kantong.id,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('‹ Kantong'),
        ),
        leadingWidth: 110,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          HeroGemi(
            label: '${kantong.name} · ${kantong.type.label}',
            nilai: 'Rp ${fmtRupiah(saldo)}',
            delta: 'Saldo awal ${fmtRupiah(kantong.initialBalance)}',
          ),
          if (daftar.isEmpty)
            const KosongGemi(
              judul: 'Belum ada transaksi di kantong ini',
              langkah: 'Catatan dengan kantong ini akan tampil di sini.',
            )
          else
            ...bukuKas(context, daftar),
        ],
      ),
    );
  }
}
