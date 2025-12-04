import 'package:flutter/material.dart';

/// Flutter equivalent of the Android vector drawable:
/// Green background with semi-transparent white grid lines.
class EffectKeyboardLayout extends StatelessWidget {
  final double size; // width & height
  const EffectKeyboardLayout({super.key, this.size = 108});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _KeyboardGridPainter(),
    );
  }
}

class _KeyboardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBackground = Paint()..color = const Color(0xFF3DDC84);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBackground);

    final paintLine = Paint()
      ..color = const Color(0x33FFFFFF) // #33FFFFFF = semi-transparent white
      ..strokeWidth = 0.8;

    // Draw vertical grid lines every 10 units
    for (double x = 9; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLine);
    }

    // Draw horizontal grid lines every 10 units
    for (double y = 9; y < size.height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintLine);
    }

    // Draw inner horizontal lines (from 19 to 79, y = 29..79)
    for (double y = 29; y <= 79; y += 10) {
      canvas.drawLine(const Offset(19, 0), const Offset(89, 0).translate(0, y - 0), paintLine);
    }

    // Draw inner vertical lines (x = 29..79, y = 19..89)
    for (double x = 29; x <= 79; x += 10) {
      canvas.drawLine(Offset(x, 19), Offset(x, 89), paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
