import 'package:flutter/material.dart';

/// A reusable rounded white background container with padding
/// Replicates:
/// <shape>
///     <solid color="@android:color/white"/>
///     <corners radius="8dp"/>
///     <padding left="8dp" right="8dp" top="8dp" bottom="8dp"/>
/// </shape>
class RoundedBackgroundDictionary extends StatelessWidget {
  final Widget? child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color color;
  final EdgeInsetsGeometry margin;

  const RoundedBackgroundDictionary({
    super.key,
    this.child,
    this.radius = 8.0,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(8.0),
    this.margin = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
