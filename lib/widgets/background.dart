import 'package:flutter/material.dart';

/// A reusable background container that mimics the Android XML shape:
/// - Solid white color
/// - 15dp corner radius
class BackgroundContainer extends StatelessWidget {
  final Widget? child;
  final double radius;
  final Color color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const BackgroundContainer({
    super.key,
    this.child,
    this.radius = 15.0,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(0),
    this.margin = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
