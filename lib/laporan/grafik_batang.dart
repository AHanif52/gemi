import 'package:flutter/material.dart';

import '../app/format.dart';
import '../app/theme.dart';

/// Batang pengeluaran per periode, 1:1 dengan bars() di prototipe: sumbu bawah,
/// batang ujung bulat, label di bawah, nilai tertinggi ditulis ringkas di atasnya,
/// batang hari ini lebih gelap. Nilai null = periode belum lewat, tidak digambar.
class GrafikBatang extends StatelessWidget {
  const GrafikBatang({super.key, required this.label, required this.nilai, this.hariIni});
  final List<String> label;
  final List<int?> nilai;
  final int? hariIni;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: CustomPaint(painter: _Painter(label, nilai, hariIni, g, Theme.of(context).colorScheme.onSurface)),
    );
  }
}

class _Painter extends CustomPainter {
  const _Painter(this.label, this.nilai, this.hariIni, this.g, this.ink);
  final List<String> label;
  final List<int?> nilai;
  final int? hariIni;
  final GemiColors g;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    const padT = 18.0, padB = 22.0;
    final n = label.length;
    final base = size.height - padB;
    final maks = nilai.whereType<int>().fold(0, (a, b) => a > b ? a : b);
    final slot = size.width / n;
    final bw = (slot - 8).clamp(4.0, 28.0);

    canvas.drawLine(Offset(0, base), Offset(size.width, base), Paint()..color = g.rule..strokeWidth = 1);

    for (var i = 0; i < n; i++) {
      final x = i * slot + (slot - bw) / 2;
      final v = nilai[i];
      if (v != null) {
        final h = maks == 0 ? 4.0 : (v / maks * (base - padT)).clamp(4.0, base - padT);
        final r = RRect.fromRectAndCorners(Rect.fromLTWH(x, base - h, bw, h), topLeft: const Radius.circular(4), topRight: const Radius.circular(4));
        canvas.drawRRect(r, Paint()..color = i == hariIni ? ink : g.ink2);
        if (v == maks && maks > 0) _teks(canvas, fmtRingkas(v), Offset(x + bw / 2, base - h - 5), bawah: false);
      }
      _teks(canvas, label[i], Offset(x + bw / 2, size.height - 6), bawah: true);
    }
  }

  void _teks(Canvas canvas, String s, Offset tengahBawah, {required bool bawah}) {
    final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(fontSize: 11, color: g.ink2)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(tengahBawah.dx - tp.width / 2, tengahBawah.dy - tp.height));
  }

  @override
  bool shouldRepaint(_Painter o) => o.nilai != nilai || o.label != label || o.hariIni != hariIni || o.g != g;
}
