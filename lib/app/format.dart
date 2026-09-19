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
const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// DateTime -> "2026-09-18" (waktu lokal). Format tanggal di DB.
String ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String hariIni() => ymd(DateTime.now());

/// "2026-09-18" -> "Hari ini", "Kemarin", atau "Jumat, 18 Sep".
String fmtTanggal(String s, {DateTime? sekarang}) {
  final d = DateTime.parse(s);
  final now = sekarang ?? DateTime.now();
  final beda = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (beda == 0) return 'Hari ini';
  if (beda == 1) return 'Kemarin';
  return '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]}';
}
