import 'package:flutter/material.dart';

/// Flutter equivalent of the Android Vector Drawable:
/// baseline_mic_24.xml
///
/// Viewport = 24x24, white fill.
class BaselineMic24 extends StatelessWidget {
  final double size;
  final Color color;

  const BaselineMic24({
    super.key,
    this.size = 24.0,
    this.color = Colors.white, // matches android:fillColor="@android:color/white"
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MicPainter(color),
    );
  }
}

class _MicPainter extends CustomPainter {
  final Color color;

  _MicPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();

    // ------------ Converted from android:pathData ------------
    // M12,14 c1.66,0 2.99,-1.34 2.99,-3 L15,5
    path.moveTo(12, 14);
    path.cubicTo(13.66, 14, 14.99, 12.66, 14.99, 11);
    path.lineTo(15, 5);

    // c0,-1.66 -1.34,-3 -3,-3 S9,3.34 9,5 v6
    path.cubicTo(15, 3.34, 13.66, 2, 12, 2);
    path.cubicTo(10.34, 2, 9, 3.34, 9, 5);
    path.lineTo(9, 11);

    // c0,1.66 1.34,3 3,3 z
    path.cubicTo(9, 12.66, 10.34, 14, 12, 14);
    path.close();

    // M17.3,11 c0,3 -2.54,5.1 -5.3,5.1 S6.7,14 6.7,11 L5,11
    path.moveTo(17.3, 11);
    path.cubicTo(17.3, 14, 14.76, 16.1, 12, 16.1);
    path.cubicTo(9.24, 16.1, 6.7, 14, 6.7, 11);
    path.lineTo(5, 11);

    // c0,3.41 2.72,6.23 6,6.72 L11,21 h2 v-3.28
    path.cubicTo(5, 14.41, 7.72, 17.23, 11, 17.72);
    path.lineTo(11, 21);
    path.lineTo(13, 21);
    path.lineTo(13, 17.72);

    // c3.28,-0.48 6,-3.3 6,-6.72 h-1.7 z
    path.cubicTo(16.28, 17.24, 19, 14.41, 19, 11);
    path.lineTo(17.3, 11);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
