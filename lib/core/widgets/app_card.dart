import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.color,
    this.shadow = AppColors.cardShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppColors.radiusCard);
    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: color ?? colors.surface.withValues(alpha: 0.72),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: onTap == null
                ? Padding(padding: padding, child: child)
                : InkWell(
                    onTap: onTap,
                    child: Padding(padding: padding, child: child),
                  ),
          ),
        ),
      ),
    );
  }
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: dark ? const Color(0xFF071523) : AppColors.background,
        child: CustomPaint(
          painter: _WeavePainter(dark: dark),
          child: child,
        ),
      ),
    );
  }
}

class _WeavePainter extends CustomPainter {
  const _WeavePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final cloth = Paint()
      ..color = (dark ? const Color(0xFF123F6B) : const Color(0xFFB9D7F5))
          .withValues(alpha: 0.38);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.64, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 270)
        ..lineTo(size.width * 0.78, 225)
        ..close(),
      cloth,
    );
    final thread = Paint()
      ..color = (dark ? Colors.white : AppColors.primary).withValues(
        alpha: dark ? 0.025 : 0.035,
      )
      ..strokeWidth = 0.7;
    for (double y = 0; y < size.height; y += 12) {
      for (double x = 0; x < size.width; x += 12) {
        canvas.drawLine(Offset(x, y), Offset(x + 5, y), thread);
        canvas.drawLine(Offset(x, y + 3), Offset(x, y + 8), thread);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WeavePainter oldDelegate) => dark != oldDelegate.dark;
}

class TicketDivider extends StatelessWidget {
  const TicketDivider({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(
      painter: _TicketDividerPainter(
        Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
  );
}

class _TicketDividerPainter extends CustomPainter {
  const _TicketDividerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + 4).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TicketDividerPainter oldDelegate) =>
      color != oldDelegate.color;
}
