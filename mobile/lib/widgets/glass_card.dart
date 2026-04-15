import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/synapse_theme.dart';

/// Glassmorphic card component — "Kinetic Glass Ethos"
///
/// Recipe from Stitch DESIGN.md:
///   Background: rgba(53, 53, 52, 0.4)
///   Backdrop-filter: blur(24px)
///   Border: 1px solid rgba(255, 255, 255, 0.05)
///   Optional glow shadow for success/error states.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blurAmount;
  final Color? glowColor;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.blurAmount = 24.0,
    this.glowColor,
    this.borderRadius = 24.0,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: SynapseTheme.glassBackground,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? SynapseTheme.glassBorder,
                width: 1,
              ),
              boxShadow: glowColor != null
                  ? [
                      BoxShadow(
                        color: glowColor!.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
