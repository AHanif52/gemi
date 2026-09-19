// Format rupiah & tanggal. Nominal selalu integer rupiah (NFR-06).

/// 5605000 -> "5.605.000". Tanpa "Rp", pemanggil yang menambah kalau perlu.
String fmtRupiah(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return n < 0 ? '−${b.toString()}' : b.toString();
}

/// "5.605.000" atau "5605000" -> 5605000. Karakter selain digit dibuang.
int parseRupiah(String s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0;

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// DateTime -> "2026-09-18" (waktu lokal). Format tanggal di DB.
String ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String hariIni() => ymd(DateTime.now());

/// DateTime -> "Jumat, 18 Sep" selalu (tanpa Hari ini/Kemarin).
String fmtTanggalPanjang(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]}';

/// "2026-09-18" -> "Hari ini", "Kemarin", atau "Jumat, 18 Sep".
String fmtTanggal(String s, {DateTime? sekarang}) {
  final d = DateTime.parse(s);
  final now = sekarang ?? DateTime.now();
  final beda = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (beda == 0) return 'Hari ini';
  if (beda == 1) return 'Kemarin';
  return '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]}';
}

const _bulanPanjang = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// DateTime -> "2026-09". Format bulan di tabel budgets.
String ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

String bulanIni() => ym(DateTime.now());

/// "2026-09" -> "September 2026"; [pendek] -> "September".
String fmtBulan(String s, {bool pendek = false}) {
  final n = _bulanPanjang[int.parse(s.substring(5, 7)) - 1];
  return pendek ? n : '$n ${s.substring(0, 4)}';
}

/// "2026-09" ± n bulan.
String geserBulan(String s, int n) => ym(
  DateTime(int.parse(s.substring(0, 4)), int.parse(s.substring(5, 7)) + n),
);

/// Hari tersisa di bulan [s] dihitung dari [sekarang], tidak termasuk hari ini.
/// Bulan lewat = 0; bulan mendatang = jumlah hari penuh.
int hariSisa(String s, {DateTime? sekarang}) {
  final now = sekarang ?? DateTime.now();
  final y = int.parse(s.substring(0, 4)), m = int.parse(s.substring(5, 7));
  final akhir = DateTime(y, m + 1, 0).day;
  if (ym(now) == s) return akhir - now.day;
  return DateTime(y, m).isAfter(now) ? akhir : 0;
}

/// Nominal ringkas untuk sumbu grafik: 1.240.000 -> "1,2 jt", 980.000 -> "980 rb", 500 -> "500".
String fmtRingkas(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1).replaceAll('.', ',')} jt';
  }
  if (n >= 1000) return '${(n / 1000).round()} rb';
  return '$n';
}

/// Senin di minggu yang memuat [d].
DateTime awalMinggu(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// "14 – 20 Sep" atau "29 Sep – 5 Okt" untuk minggu yang dimulai [senin].
String fmtRentangMinggu(DateTime senin) {
  final minggu = senin.add(const Duration(days: 6));
  return senin.month == minggu.month
      ? '${senin.day} – ${minggu.day} ${_bulan[senin.month - 1]}'
      : '${senin.day} ${_bulan[senin.month - 1]} – ${minggu.day} ${_bulan[minggu.month - 1]}';
}
