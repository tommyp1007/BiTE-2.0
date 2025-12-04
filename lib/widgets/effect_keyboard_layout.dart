import 'package:flutter/material.dart';

/// Flutter equivalent of:
///
/// <shape>
///     <stroke width="2dp" color="#07FF20" />
///     <corners radius="10dp" />
/// </shape>
///
/// Creates a rounded rectangle with a green stroke and no fill.
class EffectKeyboardLayout extends StatelessWidget {
  final Widget? child;
  final double radius;
  final double strokeWidth;
  final Color strokeColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const EffectKeyboardLayout({
    super.key,
    this.child,
    this.radius = 10.0,
    this.strokeWidth = 2.0,
    this.strokeColor = const Color(0xFF07FF20),
    this.padding = const EdgeInsets.all(8),
    this.margin = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: strokeColor,
          width: strokeWidth,
        ),
      ),
      child: child,
    );
  }
}
