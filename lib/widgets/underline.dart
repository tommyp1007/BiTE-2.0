import 'package:flutter/material.dart';

/// A reusable underline widget replicating the Android drawable:
/// <shape>
///     <solid color="@android:color/white"/>
///     <size height="2dp"/>
///     <corners radius="4dp"/>
///     <stroke color="@android:color/darker_gray" width="1dp"/>
/// </shape>
class Underline extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final Color strokeColor;
  final double strokeWidth;

  const Underline({
    super.key,
    this.width = double.infinity,
    this.height = 2.0,
    this.borderRadius = 4.0,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.grey, // corresponds to darker_gray
    this.strokeWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: strokeColor,
          width: strokeWidth,
        ),
      ),
    );
  }
}
