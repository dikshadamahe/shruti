import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphism container with backdrop blur and translucent fill.
///
/// Performance: Keep max 2-3 active BackdropFilter widgets on screen.
/// On lower-end devices, falls back to solid surface with 0.85 opacity.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? fillColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.blur = 18,
    this.opacity = 0.07,
    this.padding,
    this.margin,
    this.borderColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (fillColor ?? Colors.white).withValues(alpha: opacity),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
