import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../transaksi/transaksi_model.dart';

/// Susun CSV transaksi satu bulan (FR-15). Satu baris per transaksi, urut tanggal
/// naik; nominal integer rupiah tanpa titik supaya Sheets/Excel membacanya sebagai angka.
/// Tidak terenkripsi: ini ekspor terbaca manusia, bukan backup.
String csvBulanan(List<TransaksiBaris> daftar, String bulan) {
  final baris = daftar.where((b) => b.t.date.startsWith(bulan)).toList()
    ..sort((a, b) => a.t.date.compareTo(b.t.date));
  String sel(String? s) {
    // Kutip kalau mengandung koma, kutip, atau baris baru; kutip ganda di-escape jadi dua.
    if (s == null || s.isEmpty) return '';
    return RegExp(r'[",\r\n]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final buf = StringBuffer(
    'tanggal,jenis,kategori,kantong,kantong_tujuan,nominal,catatan\r\n',
  );
  for (final b in baris) {
    buf.write(
      [
        b.t.date,
        b.t.type.label,
        sel(b.kategori?.name),
        sel(b.kantong.name),
        sel(b.kantongTujuan?.name),
        b.t.amount,
        sel(b.t.note),
      ].join(','),
    );
    buf.write('\r\n');
  }
  return buf.toString();
}

/// Tulis CSV ke file sementara lalu buka share sheet; pola sama dengan backup.buat.
Future<void> bagikanCsvBulanan(
  List<TransaksiBaris> daftar,
  String bulan,
) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/gemi-$bulan.csv');
  await f.writeAsString(csvBulanan(daftar, bulan), flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(f.path, mimeType: 'text/csv')],
      subject: 'Laporan Gemi $bulan',
    ),
  );
  try {
    await f.delete();
  } on FileSystemException {
    /* sudah tidak ada, tidak masalah */
  }
}
