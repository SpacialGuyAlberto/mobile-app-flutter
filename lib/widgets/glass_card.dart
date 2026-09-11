import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 8.0, // Brutalist, sharper corners
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Solid background
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.dividerTheme.color ?? const Color(0xFF2D2E33),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
