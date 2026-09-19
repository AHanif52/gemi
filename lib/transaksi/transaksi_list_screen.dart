import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../widgets/baris_gemi.dart';
import 'transaksi_controller.dart';
import 'transaksi_model.dart';

/// /transaksi — semua transaksi dikelompokkan per tanggal, total harian di header (FR-03).
class TransaksiListScreen extends StatelessWidget {
  const TransaksiListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TransaksiController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: c.daftar.isEmpty
          ? const _Kosong()
          : ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: bukuKas(context, c.daftar)),
    );
  }
}

/// Susun baris transaksi jadi grup per tanggal. Dipakai Beranda dan Transaksi.
/// Total harian = masuk − keluar; transfer tidak dihitung (FR-19).
List<Widget> bukuKas(BuildContext context, List<TransaksiBaris> daftar) {
  final g = context.gemi;
  final t = Theme.of(context).textTheme;
  final widgets = <Widget>[];
  String? tanggal;
  for (var i = 0; i < daftar.length; i++) {
    final b = daftar[i];
    if (b.t.date != tanggal) {
      tanggal = b.t.date;
      var net = 0;
      for (var j = i; j < daftar.length && daftar[j].t.date == tanggal; j++) {
        net += switch (daftar[j].t.type) {
          JenisTransaksi.income => daftar[j].t.amount,
          JenisTransaksi.expense => -daftar[j].t.amount,
          JenisTransaksi.transfer => 0,
        };
      }
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(fmtTanggal(tanggal), style: t.bodySmall?.copyWith(color: g.ink2)),
            Text(
              net > 0 ? '+${fmtRupiah(net)}' : fmtRupiah(net),
              style: t.bodySmall?.copyWith(color: net > 0 ? g.income : net < 0 ? g.over : g.ink2, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ));
    }
    final (tanda, warna) = switch (b.t.type) {
      JenisTransaksi.income => ('+', g.income),
      JenisTransaksi.expense => ('−', g.over),
      JenisTransaksi.transfer => ('', g.ink3),
    };
    widgets.add(BarisGemi(key: Key('transaksi.${b.t.id}'), judul: b.judul, sub: b.sub, nominal: '$tanda${fmtRupiah(b.t.amount)}', warnaNominal: warna));
  }
  return widgets;
}

class _Kosong extends StatelessWidget {
  const _Kosong();

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Text('Belum ada transaksi', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Ketuk + untuk mencatat yang pertama.', style: TextStyle(color: g.ink2)),
        ],
      ),
    );
  }
}
