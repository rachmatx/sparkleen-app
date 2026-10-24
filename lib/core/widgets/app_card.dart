import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.gradient,
    this.shadow = AppColors.cardShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppColors.radiusCard);

    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: Material(
        color: gradient == null ? AppColors.surface : Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: gradient == null
              ? null
              : BoxDecoration(gradient: gradient, borderRadius: radius),
          child: onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(
                  onTap: onTap,
                  child: Padding(padding: padding, child: child),
                ),
        ),
      ),
    );
  }
}
