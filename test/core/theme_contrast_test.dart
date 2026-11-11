import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/theme/app_colors.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    test(
      '${brightness.name}: text, links and input boundaries retain contrast',
      () {
        final theme = buildAppTheme(brightness: brightness);
        final colors = theme.colorScheme;
        final canvas = brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.background;
        final card = Color.alphaBlend(
          colors.surface.withValues(alpha: .75),
          canvas,
        );
        for (final surface in [canvas, card]) {
          expect(
            contrast(colors.onSurface, surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(colors.onSurfaceVariant, surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(contrast(colors.primary, surface), greaterThanOrEqualTo(4.5));
        }
        final input = theme.inputDecorationTheme;
        final border = input.enabledBorder! as OutlineInputBorder;
        expect(
          contrast(border.borderSide.color, input.fillColor!),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrast(colors.primary, colors.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(Colors.white, AppColors.primary),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }
}
