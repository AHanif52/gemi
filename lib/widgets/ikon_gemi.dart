import 'package:flutter/material.dart';

/// Ikon tab bar, 1:1 dengan SVG di design/prototype.html (viewBox 24, stroke 1.6, ujung bulat).
/// Digambar sendiri supaya tidak butuh package SVG (NFR-12).
enum IkonGemi { beranda, transaksi, budget, laporan }

class IkonTab extends StatelessWidget {
  const IkonTab(this.ikon, {super.key, this.ukuran = 22, this.warna});
  final IkonGemi ikon;
  final double ukuran;
  final Color? warna;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(ukuran),
    painter: _Painter(
      ikon,
      warna ?? IconTheme.of(context).color ?? Colors.black,
    ),
  );
}

class _Painter extends CustomPainter {
  const _Painter(this.ikon, this.warna);
  final IkonGemi ikon;
  final Color warna;

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
    switch (ikon) {
      case IkonGemi.beranda: // M4 11 12 4l8 7v9H4z
        canvas.drawPath(
          Path()
            ..moveTo(4, 11)
            ..lineTo(12, 4)
            ..lineTo(20, 11)
            ..lineTo(20, 20)
            ..lineTo(4, 20)
            ..close(),
          p,
        );
      case IkonGemi.transaksi: // M5 6h14M5 12h14M5 18h9
        canvas.drawLine(const Offset(5, 6), const Offset(19, 6), p);
        canvas.drawLine(const Offset(5, 12), const Offset(19, 12), p);
        canvas.drawLine(const Offset(5, 18), const Offset(14, 18), p);
      case IkonGemi.budget: // rect 4,5 16x14 rx2 + M4 11h16
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 5, 16, 14),
            const Radius.circular(2),
          ),
          p,
        );
        canvas.drawLine(const Offset(4, 11), const Offset(20, 11), p);
      case IkonGemi.laporan: // M5 19V9M12 19V5M19 19v-8
        canvas.drawLine(const Offset(5, 19), const Offset(5, 9), p);
        canvas.drawLine(const Offset(12, 19), const Offset(12, 5), p);
        canvas.drawLine(const Offset(19, 19), const Offset(19, 11), p);
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.ikon != ikon || old.warna != warna;
}
