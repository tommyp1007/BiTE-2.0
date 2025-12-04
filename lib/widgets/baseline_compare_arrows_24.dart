import 'package:flutter/material.dart';

/// A Flutter equivalent of the Android Vector Drawable:
/// baseline_compare_arrows_24.xml
///
/// Viewport = 24x24, PathData converted to Flutter Path.
class BaselineCompareArrows24 extends StatelessWidget {
  final double size;
  final Color color;

  const BaselineCompareArrows24({
    super.key,
    this.size = 24.0,
    this.color = Colors.white, // matches android:fillColor="@android:color/white"
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CompareArrowsPainter(color),
    );
  }
}

class _CompareArrowsPainter extends CustomPainter {
  final Color color;

  _CompareArrowsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();

    // ----- Converted from android:pathData -----
    // M9.01,14 H2 v2 h7.01 v3 L13,15 l-3.99,-4 V14 z
    path.moveTo(9.01, 14);
    path.lineTo(2, 14);
    path.lineTo(2, 16);
    path.lineTo(9.01, 16);
    path.lineTo(9.01, 19);
    path.lineTo(13, 15);
    path.lineTo(9.01, 11);
    path.lineTo(9.01, 14);
    path.close();

    // M14.99,13 v-3 H22 V8 h-7.01 V5 L11,9 L14.99,13 z
    path.moveTo(14.99, 13);
    path.lineTo(14.99, 10);
    path.lineTo(22, 10);
    path.lineTo(22, 8);
    path.lineTo(14.99, 8);
    path.lineTo(14.99, 5);
    path.lineTo(11, 9);
    path.lineTo(14.99, 13);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
