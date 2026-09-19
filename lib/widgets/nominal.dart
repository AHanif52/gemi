import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../pengaturan/sembunyi_controller.dart';

/// Teks nominal yang ikut FR-21: kalau disembunyikan, tampil "••••••" (tanpa siluet digit).
/// [awalan] ("Rp ") tetap tampil supaya pembaca tahu itu uang.
class Nominal extends StatelessWidget {
  const Nominal(this.teks, {super.key, this.style, this.awalan = ''});
  final String teks;
  final TextStyle? style;
  final String awalan;

  @override
  Widget build(BuildContext context) {
    final sembunyi = context.watch<SembunyiController>().aktif;
    final s = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (!sembunyi) return Text('$awalan$teks', style: s);
    return Text(
      '$awalan••••••',
      style: s.copyWith(
        color: awalan.isEmpty ? context.gemi.ink2 : s.color,
        letterSpacing: 1,
      ),
    );
  }
}

/// Tombol mata (ikon 1:1 dengan prototipe) untuk toggle sembunyikan nominal.
class TombolMata extends StatelessWidget {
  const TombolMata({super.key, this.ukuran = 22});
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SembunyiController>();
    return IconButton(
      key: const Key('nominal.mata'),
      tooltip: c.aktif ? 'Tampilkan nominal' : 'Sembunyikan nominal',
      onPressed: c.toggle,
      icon: CustomPaint(
        size: Size.square(ukuran),
        painter: _MataPainter(context.gemi.ink2, coret: c.aktif),
      ),
    );
  }
}

class _MataPainter extends CustomPainter {
  const _MataPainter(this.warna, {required this.coret});
  final Color warna;
  final bool coret;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = warna
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.scale(s);
    // M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12z
    canvas.drawPath(
      Path()
        ..moveTo(2, 12)
        ..cubicTo(5.5, 6, 8, 6, 12, 6)
        ..cubicTo(16, 6, 18.5, 6, 22, 12)
        ..cubicTo(18.5, 18, 16, 18, 12, 18)
        ..cubicTo(8, 18, 5.5, 18, 2, 12)
        ..close(),
      p,
    );
    canvas.drawCircle(const Offset(12, 12), 3, p);
    if (coret) canvas.drawLine(const Offset(4, 20), const Offset(20, 4), p);
  }

  @override
  bool shouldRepaint(_MataPainter o) => o.warna != warna || o.coret != coret;
}
