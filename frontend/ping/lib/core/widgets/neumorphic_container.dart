import 'package:flutter/material.dart';
import 'package:ping/core/theme/app_theme.dart';

/// Reusable Neumorphic Container for dark theme
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool isPressed;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: isPressed
            ? NeumorphicStyles.pressedShadows
            : NeumorphicStyles.cardShadows,
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 1),
      ),
      child: child,
    );
  }
}
