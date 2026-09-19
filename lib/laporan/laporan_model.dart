import '../app/database.dart';

/// Total satu kategori dalam rentang laporan.
class KategoriTotal {
  const KategoriTotal({
    required this.kategori,
    required this.total,
    required this.jumlah,
  });
  final Kategori kategori;
  final int total, jumlah;
}

/// Agregat satu rentang tanggal (inklusif). Dipakai harian, mingguan, bulanan;
/// layar yang memotong per hari / per minggu / top 5 dari sini.
class Ringkasan {
  const Ringkasan({
    required this.dari,
    required this.sampai,
    required this.masuk,
    required this.keluar,
    required this.keluarPerHari,
    required this.keluarPerKategori,
  });
  final String dari, sampai;
  final int masuk, keluar;
  final Map<String, int> keluarPerHari;
  final List<KategoriTotal> keluarPerKategori; // urut terbesar

  int get selisih => masuk - keluar;
}
