import 'package:flutter/material.dart';

/// A reusable rounded background container that replicates:
/// <shape>
///     <solid color="@color/colorSecondary" />
///     <corners radius="16dp" />
/// </shape>
class RoundedBackground extends StatelessWidget {
  final Widget? child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const RoundedBackground({
    super.key,
    this.child,
    this.color = const Color(0xFF03DAC5), // Replace with your colorSecondary
    this.radius = 16.0,
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
