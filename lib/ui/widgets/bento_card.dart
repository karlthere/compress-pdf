import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom Bento Box Container dengan Efek Glassmorphism Semitransparan
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 22.0,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              const BoxShadow(
                color: AppTheme.glassShadow,
                blurRadius: 24,
                spreadRadius: -4,
                offset: Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: AppTheme.glassBlur,
          child: Container(
            padding: padding ?? const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: AppTheme.glassGlossGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: AppTheme.glassBorder,
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
