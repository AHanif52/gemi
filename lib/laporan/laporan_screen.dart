import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../budget/budget_controller.dart';
import '../transaksi/transaksi_controller.dart';
import '../transaksi/transaksi_list_screen.dart';
import '../widgets/baris_gemi.dart';
import '../widgets/hero_gemi.dart';
import 'csv_bulanan.dart';
import 'grafik_batang.dart';
import 'grafik_donat.dart';
import 'laporan_controller.dart';

enum Periode { hari, minggu, bulan }

/// /laporan/{hari,minggu,bulan} — tiga angka ringkas, satu grafik, rincian (FR-09–13).
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key, this.periode = Periode.minggu});
  final Periode periode;

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  late var _periode = widget.periode;
  // Titik acuan tiap periode disimpan terpisah supaya ganti tab tidak mereset navigasi.
  var _hari = DateTime.now();
  var _senin = awalMinggu(DateTime.now());
  var _bulan = bulanIni();

  void _geser(int n) => setState(() {
    switch (_periode) {
      case Periode.hari:
        _hari = _hari.add(Duration(days: n));
      case Periode.minggu:
        _senin = _senin.add(Duration(days: 7 * n));
      case Periode.bulan:
        _bulan = geserBulan(_bulan, n);
    }
  });

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    final judul = switch (_periode) {
      Periode.hari =>
        fmtTanggal(ymd(_hari)) == 'Hari ini'
            ? 'Hari ini, ${_hari.day} ${fmtBulan(ym(_hari), pendek: true).substring(0, 3)}'
            : fmtTanggal(ymd(_hari)),
      Periode.minggu => fmtRentangMinggu(_senin),
      Periode.bulan => fmtBulan(
        _bulan,
        pendek: _bulan.startsWith(bulanIni().substring(0, 4)),
      ),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: g.rule)),
            ),
            child: Row(
              children: [
                for (final p in Periode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: InkWell(
                      key: Key('laporan.${p.name}'),
                      onTap: () => setState(() => _periode = p),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: p == _periode ? ink : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          switch (p) {
                            Periode.hari => 'Hari',
                            Periode.minggu => 'Minggu',
                            Periode.bulan => 'Bulan',
                          },
                          style: TextStyle(
                            color: p == _periode ? ink : g.ink2,
                            fontWeight: p == _periode ? FontWeight.w500 : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                IconButton(
                  key: const Key('laporan.sebelumnya'),
                  onPressed: () => _geser(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    judul,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  key: const Key('laporan.berikutnya'),
                  onPressed: () => _geser(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          switch (_periode) {
            Periode.hari => _Hari(_hari),
            Periode.minggu => _Minggu(_senin),
            Periode.bulan => _Bulan(_bulan),
          },
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

/// FR-09: masuk, keluar, selisih + daftar transaksi hari itu.
class _Hari extends StatelessWidget {
  const _Hari(this.hari);
  final DateTime hari;

  @override
  Widget build(BuildContext context) {
    final tgl = ymd(hari);
    final r = context.watch<LaporanController>().data(tgl, tgl);
    final daftar = context
        .watch<TransaksiController>()
        .daftar
        .where((b) => b.t.date == tgl)
        .toList();
    if (r == null) return const SizedBox(height: 200);
    final ini = tgl == hariIni();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroGemi(
          label: ini ? 'Keluar hari ini' : 'Keluar',
          nilai: 'Rp ${fmtRupiah(r.keluar)}',
          delta: r.masuk > 0
              ? 'Masuk ${fmtRupiah(r.masuk)} · selisih ${fmtRupiah(r.selisih)}'
              : 'Belum ada pemasukan${ini ? ' hari ini' : ''}',
        ),
        if (daftar.isEmpty)
          Text('Tidak ada catatan.', style: TextStyle(color: context.gemi.ink2))
        else
          ...bukuKas(context, daftar),
      ],
    );
  }
}

/// FR-10: masuk/keluar, batang per hari Sen–Min, top 5 kategori.
class _Minggu extends StatelessWidget {
  const _Minggu(this.senin);
  final DateTime senin;

  static const _label = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final dari = ymd(senin), sampai = ymd(senin.add(const Duration(days: 6)));
    final r = context.watch<LaporanController>().data(dari, sampai);
    if (r == null) return const SizedBox(height: 200);
    final ini = hariIni();
    final hariKe = DateTime.now()
        .difference(senin)
        .inDays; // 0..6 kalau minggu ini
    final mingguIni = hariKe >= 0 && hariKe < 7;
    final nilai = <int?>[
      for (var i = 0; i < 7; i++)
        if (mingguIni && i > hariKe)
          null
        else
          r.keluarPerHari[ymd(senin.add(Duration(days: i)))] ?? 0,
    ];
    final hariLewat = mingguIni
        ? hariKe + 1
        : (dari.compareTo(ini) > 0 ? 0 : 7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroGemi(
          label: mingguIni ? 'Keluar minggu ini' : 'Keluar',
          nilai: 'Rp ${fmtRupiah(r.keluar)}',
          delta: [
            if (hariLewat > 0)
              'Rata-rata ${fmtRupiah((r.keluar / hariLewat / 1000).round() * 1000)} per hari',
            r.masuk > 0 ? 'masuk ${fmtRupiah(r.masuk)}' : 'belum ada pemasukan',
          ].join(' · '),
        ),
        GrafikBatang(
          label: _label,
          nilai: nilai,
          hariIni: mingguIni ? hariKe : null,
        ),
        _Judul('Kategori terbesar'),
        if (r.keluarPerKategori.isEmpty)
          Text(
            'Belum ada pengeluaran.',
            style: TextStyle(color: context.gemi.ink2),
          ),
        for (final k in r.keluarPerKategori.take(5))
          BarisGemi(
            judul: k.kategori.name,
            sub: '${k.jumlah} catatan',
            nominal: fmtRupiah(k.total),
          ),
      ],
    );
  }
}

/// FR-11/12: tabungan bersih vs bulan lalu, batang per minggu, donat komposisi, terpakai/budget.
class _Bulan extends StatelessWidget {
  const _Bulan(this.bulan);
  final String bulan;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    final akhir = DateTime(
      int.parse(bulan.substring(0, 4)),
      int.parse(bulan.substring(5, 7)) + 1,
      0,
    ).day;
    final lalu = geserBulan(bulan, -1);
    final akhirLalu = DateTime(
      int.parse(lalu.substring(0, 4)),
      int.parse(lalu.substring(5, 7)) + 1,
      0,
    ).day;
    final laporan = context.watch<LaporanController>();
    final r = laporan.data('$bulan-01', '$bulan-$akhir');
    final rLalu = laporan.data('$lalu-01', '$lalu-$akhirLalu');
    final budget = context.watch<BudgetController>().data(bulan);
    if (r == null || rLalu == null) return const SizedBox(height: 200);

    final bulanIniKah = bulan == bulanIni();
    final hariKe = DateTime.now().day; // dipakai hanya kalau bulan ini
    // Batang per minggu kalender: 1–7, 8–14, 15–21, 22–akhir.
    final batas = [1, 8, 15, 22, akhir + 1];
    final label = [
      for (var i = 0; i < 4; i++) '${batas[i]}–${batas[i + 1] - 1}',
    ];
    final mingguIni = bulanIniKah
        ? batas.indexWhere((b) => b > hariKe) - 1
        : null;
    final nilai = <int?>[
      for (var i = 0; i < 4; i++)
        if (bulanIniKah && batas[i] > hariKe)
          null
        else
          r.keluarPerHari.entries
              .where((e) {
                final d = int.parse(e.key.substring(8));
                return d >= batas[i] && d < batas[i + 1];
              })
              .fold<int>(0, (a, e) => a + e.value),
    ];

    final tabungan = r.selisih, tabunganLalu = rLalu.selisih;
    final banding = tabunganLalu > 0 && tabungan >= 0
        ? '${tabungan >= tabunganLalu ? 'naik' : 'turun'} ${((tabungan - tabunganLalu).abs() * 100 / tabunganLalu).round()}% dari ${fmtBulan(lalu, pendek: true)}'
        : null;

    final totalKeluar = r.keluar;
    final komposisi = r.keluarPerKategori.take(5).toList();
    final lainnya = totalKeluar - komposisi.fold(0, (a, k) => a + k.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroGemi(
          label: bulanIniKah ? 'Tabungan bulan ini' : 'Tabungan',
          nilai: 'Rp ${fmtRupiah(tabungan)}',
          delta: [
            'Masuk ${fmtRupiah(r.masuk)}',
            'keluar ${fmtRupiah(r.keluar)}',
            ?banding,
          ].join(' · '),
        ),
        GrafikBatang(label: label, nilai: nilai, hariIni: mingguIni),
        if (totalKeluar > 0) ...[
          _Judul('Komposisi pengeluaran'),
          Row(
            children: [
              GrafikDonat(
                porsi: [
                  for (final k in komposisi) k.total / totalKeluar,
                  if (lainnya > 0) lainnya / totalKeluar,
                ],
                warna: [
                  for (final k in komposisi) g.kategori(k.kategori.color),
                  if (lainnya > 0) g.kategori(5),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    for (final k in komposisi)
                      _Legenda(
                        warna: g.kategori(k.kategori.color),
                        nama: k.kategori.name,
                        persen: k.total * 100 ~/ totalKeluar,
                      ),
                    if (lainnya > 0)
                      _Legenda(
                        warna: g.kategori(5),
                        nama: 'Lainnya',
                        persen: lainnya * 100 ~/ totalKeluar,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (budget != null && budget.adaBudget) ...[
          _Judul('Terpakai / budget'),
          for (final b in budget.baris.where((b) => b.plafon > 0))
            BarisGemi(
              judul: b.kategori.name,
              nominal: '${fmtRupiah(b.pakai)} / ${fmtRupiah(b.plafon)}',
              warnaNominal: b.lewat ? g.over : null,
            ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ink),
                bottom: BorderSide(color: ink, width: 3),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Semua kategori',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${fmtRupiah(budget.totalPakai)} / ${fmtRupiah(budget.totalPlafon)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: BarisGemi(
            key: const Key('laporan.csv'),
            judul: 'Ekspor CSV bulan ini',
            sub: 'Tidak terenkripsi, bisa dibuka di Sheets/Excel',
            ekor: const Icon(Icons.chevron_right),
            onTap: () => bagikanCsvBulanan(
              context.read<TransaksiController>().daftar,
              bulan,
            ),
          ),
        ),
      ],
    );
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.s);
  final String s;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 4),
    child: Text(
      s,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.gemi.ink2,
      ),
    ),
  );
}

class _Legenda extends StatelessWidget {
  const _Legenda({
    required this.warna,
    required this.nama,
    required this.persen,
  });
  final Color warna;
  final String nama;
  final int persen;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(nama)),
        Text(
          '$persen%',
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ],
    ),
  );
}
