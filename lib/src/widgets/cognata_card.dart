import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CognataCard extends StatelessWidget {
  const CognataCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 12,
    this.onTap,
    this.color = CognataColors.card,
    this.borderColor = CognataColors.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: borderColor),
    );

    return Material(
      color: color,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        overlayColor: WidgetStatePropertyAll(
          CognataColors.accent.withValues(alpha: 0.04),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
