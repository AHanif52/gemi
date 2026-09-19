import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../transaksi/transaksi_controller.dart';
import '../transaksi/transaksi_list_screen.dart';
import '../widgets/baris_gemi.dart';
import '../widgets/hero_gemi.dart';
import '../widgets/kosong_gemi.dart';
import '../widgets/ribuan_formatter.dart';
import 'kantong_controller.dart';
import '../app/database.dart' show Kantong;

/// /kantong/{nama} — saldo satu kantong + transaksinya saja, termasuk transfer
/// masuk/keluar (FR-22). Pola daftar sama dengan /transaksi.
class KantongDetailScreen extends StatelessWidget {
  const KantongDetailScreen(this.kantong, {super.key});
  final Kantong kantong;

  /// FR-20: dialog saldo riil -> controller catat selisih -> toast dengan Batalkan.
  Future<void> _sesuaikan(BuildContext context, int saldoSekarang) async {
    final c = context.read<TransaksiController>();
    final messenger = ScaffoldMessenger.of(context);
    final input = TextEditingController(text: fmtRupiah(saldoSekarang));
    final saldoRiil = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Saldo ${kantong.name} sekarang'),
        content: TextField(
          key: const Key('kantong.saldoRiil'),
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            RibuanFormatter(),
          ],
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            helperMaxLines: 2,
            helperText:
                'Lihat di aplikasi bank atau e-money, ketik apa adanya.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            key: const Key('kantong.sesuaikan.simpan'),
            onPressed: () => Navigator.pop(ctx, parseRupiah(input.text)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saldoRiil == null) return;
    final id = await c.sesuaikanSaldo(kantong: kantong, saldoRiil: saldoRiil);
    if (id == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Saldo sudah sesuai')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Selisih ${fmtRupiah((saldoRiil - saldoSekarang).abs())} dicatat',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Batalkan', onPressed: () => c.hapus(id)),
      ),
    );
  }

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
          ),
          BarisTautan(
            key: const Key('kantong.sesuaikan'),
            label: 'Sesuaikan saldo',
            sub: 'Ketik saldo riil, selisihnya dicatat otomatis',
            onTap: () => _sesuaikan(context, saldo),
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
