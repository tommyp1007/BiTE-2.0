import 'package:flutter/material.dart';

/// Flutter equivalent of ic_launcher_foreground.xml
class ICLauncherForeground extends StatelessWidget {
  final double size;

  const ICLauncherForeground({super.key, this.size = 108});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ICLauncherPainter(),
    );
  }
}

class _ICLauncherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor to match original viewport 108x108
    final double scaleX = size.width / 108.0;
    final double scaleY = size.height / 108.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // ----- Gradient path -----
    final Rect gradientRect = Rect.fromLTWH(42.9492, 49.59793, 42.89837, 42.89837);
    final Paint gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-1, -1), // approx from startX/startY
        end: Alignment(1, 1), // approx from endX/endY
        colors: [
          Color(0x44000000),
          Color(0x00000000),
        ],
      ).createShader(gradientRect);

    final Path gradientPath = Path()
      ..moveTo(31, 63.928)
      ..relativeCubicTo(0, 0, 6.4 - 0, -11, 12.1 - 6.4, -13.1 + 11)
      ..relativeCubicTo(7.2, -2.6, 26 - 12.1, -1.4 + 13.1, 26 - 12.1, -1.4 + 13.1)
      ..lineTo(95.1, 49.528) // approx 31+26+38.1 ?
      ..lineTo(107, 108.928)
      ..lineTo(75, 107.928)
      ..lineTo(31, 63.928)
      ..close();

    canvas.drawPath(gradientPath, gradientPaint);

    // ----- White foreground path -----
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path whitePath = Path()
      ..moveTo(65.3, 45.828)
      ..relativeLineTo(3.8, -6.6)
      ..relativeCubicTo(0.2, -0.4, 0.1, -0.9, -0.3, -1.1)
      ..relativeCubicTo(-0.4, -0.2, -0.9, -0.1, -1.1, 0.3)
      ..lineTo(64.1, 45.828) // adjust approximation
      ..lineTo(60.2, 39.128)
      ..relativeCubicTo(-6.3, -2.8, -13.4, -2.8, -19.7, 0)
      ..lineTo(36.6, 39.228)
      ..relativeCubicTo(-0.2, -0.4, -0.7, -0.5, -1.1, -0.3)
      ..relativeCubicTo(-0.2, 0.2, -0.1, 0.6, 0.1, 1)
      ..lineTo(40.4, 45.428)
      ..lineTo(31, 63.928)
      ..lineTo(77, 63.928)
      ..lineTo(65.3, 45.828)
      ..close();

    // Circles (dots)
    final Path dot1 = Path()..addOval(Rect.fromCircle(center: const Offset(43.4, 57.328), radius: 1.0));
    final Path dot2 = Path()..addOval(Rect.fromCircle(center: const Offset(64.6, 57.328), radius: 1.0));

    canvas.drawPath(whitePath, whitePaint);
    canvas.drawPath(dot1, whitePaint);
    canvas.drawPath(dot2, whitePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
