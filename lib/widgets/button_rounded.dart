import 'package:flutter/material.dart';

/// A reusable rounded button background that replicates:
/// <shape>
///     <corners radius="20dp" />
///     <solid color="@color/colorSecondary" />
/// </shape>
class ButtonRounded extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double radius;
  final Color color;
  final EdgeInsetsGeometry padding;

  const ButtonRounded({
    super.key,
    required this.child,
    this.onPressed,
    this.radius = 20.0,
    this.color = const Color(0xFF03DAC5), // Replace with your colorSecondary
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(child: child),
    );

    // If onPressed is provided, make it clickable.
    if (onPressed != null) {
      return GestureDetector(
        onTap: onPressed,
        child: button,
      );
    }

    // If no onPressed, return static container.
    return button;
  }
}
