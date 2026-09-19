import 'dart:math';

import 'package:flutter/material.dart';

/// Donat komposisi, 1:1 dengan donut() di prototipe: cincin tebal 12 dari 104,
/// mulai jam 12, celah 2 unit antar irisan. [porsi] = pecahan 0..1 per warna.
class GrafikDonat extends StatelessWidget {
  const GrafikDonat({super.key, required this.porsi, required this.warna, this.ukuran = 104});
  final List<double> porsi;
  final List<Color> warna;
  final double ukuran;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(ukuran), painter: _Painter(porsi, warna));
}

class _Painter extends CustomPainter {
  const _Painter(this.porsi, this.warna);
  final List<double> porsi;
  final List<Color> warna;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 104;
    final rect = Rect.fromCircle(center: Offset(52 * s, 52 * s), radius: 40 * s);
    final celah = 2 / (2 * pi * 40) * 2 * pi; // 2 unit keliling dalam radian
    var mulai = -pi / 2;
    for (var i = 0; i < porsi.length; i++) {
      final sapu = 2 * pi * porsi[i];
      if (sapu > celah) {
        canvas.drawArc(rect, mulai, sapu - celah, false, Paint()..color = warna[i]..style = PaintingStyle.stroke..strokeWidth = 12 * s);
      }
      mulai += sapu;
    }
  }

  @override
  bool shouldRepaint(_Painter o) => o.porsi != porsi || o.warna != warna;
}
