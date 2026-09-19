import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../widgets/kosong_gemi.dart';
import 'transaksi_controller.dart';
import 'transaksi_list_screen.dart';
import 'transaksi_model.dart';

/// Saring daftar transaksi (FR-04): kata cocok di catatan / kategori / kantong
/// (tanpa peduli huruf besar-kecil), tanggal di dalam [dari]..[sampai] inklusif.
/// Dipisah dari layar supaya bisa diuji tanpa widget.
List<TransaksiBaris> cariTransaksi(
  List<TransaksiBaris> daftar, {
  String kata = '',
  String? dari,
  String? sampai,
}) {
  final q = kata.trim().toLowerCase();
  return [
    for (final b in daftar)
      if ((dari == null || b.t.date.compareTo(dari) >= 0) &&
          (sampai == null || b.t.date.compareTo(sampai) <= 0) &&
          (q.isEmpty ||
              [
                b.t.note,
                b.kategori?.name,
                b.kantong.name,
                b.kantongTujuan?.name,
              ].any((s) => s?.toLowerCase().contains(q) == true)))
        b,
  ];
}

/// /transaksi/cari — kolom kata di app bar, filter rentang tanggal opsional,
/// hasil dalam buku kas yang sama dengan FR-03.
class TransaksiCariScreen extends StatefulWidget {
  const TransaksiCariScreen({super.key});

  @override
  State<TransaksiCariScreen> createState() => _TransaksiCariScreenState();
}

class _TransaksiCariScreenState extends State<TransaksiCariScreen> {
  var _kata = '';
  DateTimeRange? _rentang;

  Future<void> _pilihRentang() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDateRange: _rentang,
    );
    if (r != null) setState(() => _rentang = r);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final hasil = cariTransaksi(
      context.watch<TransaksiController>().daftar,
      kata: _kata,
      dari: _rentang == null ? null : ymd(_rentang!.start),
      sampai: _rentang == null ? null : ymd(_rentang!.end),
    );
    final adaFilter = _kata.trim().isNotEmpty || _rentang != null;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('transaksi.cari.kata'),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari catatan, kategori, kantong',
            border: InputBorder.none,
          ),
          onChanged: (s) => setState(() => _kata = s),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              key: const Key('transaksi.cari.tanggal'),
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text(
                _rentang == null
                    ? 'Rentang tanggal'
                    : '${fmtTanggalPanjang(_rentang!.start)} – ${fmtTanggalPanjang(_rentang!.end)}',
              ),
              onPressed: _pilihRentang,
              onDeleted: _rentang == null
                  ? null
                  : () => setState(() => _rentang = null),
            ),
          ),
          if (!adaFilter)
            Text(
              'Ketik kata atau pilih rentang tanggal.',
              style: TextStyle(color: g.ink2),
            )
          else if (hasil.isEmpty)
            const KosongGemi(
              judul: 'Tidak ada yang cocok',
              langkah: 'Coba kata lain atau lebarkan rentang tanggal.',
            )
          else
            ...bukuKas(context, hasil),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}
