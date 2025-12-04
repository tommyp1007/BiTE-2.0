import 'package:flutter/material.dart';

/// Flutter equivalent of outline_backspace_32.xml
class OutlineBackspace32 extends StatelessWidget {
  final double size;
  final Color color;

  const OutlineBackspace32({
    super.key,
    this.size = 44.0,
    this.color = Colors.white, // matches android:fillColor="@android:color/white"
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BackspacePainter(color),
    );
  }
}

class _BackspacePainter extends CustomPainter {
  final Color color;

  _BackspacePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / 24.0;
    final double scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();

    // ----- Converted pathData -----
    path.moveTo(22, 3);
    path.lineTo(7, 3);
    path.cubicTo(6.31, 3, 5.77, 3.35, 5.41, 3.88);
    path.lineTo(0, 12);
    path.lineTo(5.41, 20.11);
    path.cubicTo(5.77, 20.64, 6.31, 21, 7, 21);
    path.lineTo(22, 21);
    path.cubicTo(23.1, 21, 24, 20.1, 24, 19);
    path.lineTo(24, 5);
    path.cubicTo(24, 3.9, 23.1, 3, 22, 3);
    path.close();

    path.moveTo(22, 19);
    path.lineTo(7.07, 19);
    path.lineTo(2.4, 12);
    path.lineTo(7.06, 5);
    path.lineTo(22, 5);
    path.lineTo(22, 19);
    path.close();

    // X shape inside backspace
    path.moveTo(10.41, 17);
    path.lineTo(14, 13.41);
    path.lineTo(17.59, 17);
    path.lineTo(19, 15.59);
    path.lineTo(15.41, 12);
    path.lineTo(19, 8.41);
    path.lineTo(17.59, 7);
    path.lineTo(14, 10.59);
    path.lineTo(10.41, 7);
    path.lineTo(9, 8.41);
    path.lineTo(12.59, 12);
    path.lineTo(9, 15.59);
    path.lineTo(10.41, 17);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
