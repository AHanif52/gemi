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
