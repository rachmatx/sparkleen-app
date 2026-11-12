import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    primary: dark ? const Color(0xFF8AB4FF) : AppColors.link,
    onPrimary: dark ? const Color(0xFF0B1220) : Colors.white,
    primaryContainer: dark ? const Color(0xFF173756) : AppColors.primarySoft,
    onPrimaryContainer: dark ? const Color(0xFFB5D6FF) : AppColors.primaryDark,
    secondary: dark ? const Color(0xFF85BBFF) : AppColors.primary,
    onSecondary: dark ? const Color(0xFF0B1220) : Colors.white,
    secondaryContainer: dark ? const Color(0xFF173756) : AppColors.primarySoft,
    onSecondaryContainer: dark
        ? const Color(0xFFB5D6FF)
        : AppColors.primaryDark,
    surface: dark ? const Color(0xFF172437) : AppColors.surface,
    surfaceDim: dark ? const Color(0xFF0B1220) : AppColors.surfaceMuted,
    surfaceBright: dark ? const Color(0xFF2C455E) : AppColors.surface,
    surfaceContainerLowest: dark ? const Color(0xFF0B1220) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF0D2035) : AppColors.surface,
    surfaceContainer: dark ? const Color(0xFF172437) : AppColors.background,
    surfaceContainerHigh: dark
        ? const Color(0xFF193149)
        : AppColors.surfaceMuted,
    surfaceContainerHighest: dark ? const Color(0xFF233B54) : AppColors.border,
    onSurface: dark ? const Color(0xFFF0F6FD) : AppColors.text,
    onSurfaceVariant: dark ? const Color(0xFFB0BFD2) : AppColors.muted,
    outline: dark ? const Color(0xFF8299B1) : AppColors.soft,
    outlineVariant: dark ? const Color(0xFF2D4058) : AppColors.border,
    inverseSurface: dark ? AppColors.surface : AppColors.text,
    onInverseSurface: dark ? AppColors.text : AppColors.surface,
    inversePrimary: dark ? AppColors.primary : const Color(0xFF85BBFF),
    error: dark ? const Color(0xFFFFA6B8) : AppColors.danger,
    onError: dark ? const Color(0xFF4A1020) : Colors.white,
    errorContainer: dark ? const Color(0xFF4A2030) : AppColors.dangerSoft,
    onErrorContainer: dark ? const Color(0xFFFFD9E1) : const Color(0xFF780D28),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    scaffoldBackgroundColor: Colors.transparent,
  );

  final textTheme = base.textTheme.copyWith(
    headlineLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 28,
      height: 1.16,

      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: colors.onSurface,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 26,
      height: 1.18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      color: colors.onSurface,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.45,
      color: colors.onSurface,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      height: 1.22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: colors.onSurface,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: colors.onSurface,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: colors.onSurface,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      height: 1.35,
      color: colors.onSurface,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 1.35,
      color: colors.onSurface,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      height: 1.35,
      color: colors.onSurfaceVariant,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: colors.onSurface,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colors.onSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colors.onSurfaceVariant,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) =>
          const Icon(Icons.chevron_left_rounded),
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
      titleSpacing: 4,
      toolbarHeight: 60,
      leadingWidth: 48,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colors.surface.withValues(alpha: 0.75),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      floatingLabelStyle: textTheme.labelMedium?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: colors.onSurfaceVariant,
      suffixIconColor: colors.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusInput),
        borderSide: BorderSide(color: colors.outline, width: 0.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusInput),
        borderSide: BorderSide(color: colors.outline, width: 0.6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusInput),
        borderSide: BorderSide(color: colors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusInput),
        borderSide: BorderSide(color: colors.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusInput),
        borderSide: BorderSide(color: colors.error, width: 1.6),
      ),
      errorStyle: textTheme.bodySmall?.copyWith(color: colors.error),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        backgroundColor: dark ? const Color(0xFF1D5FCC) : AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.outlineVariant, width: 1),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: colors.primary,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconTheme: IconThemeData(color: colors.onSurfaceVariant),
    dividerTheme: DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primaryContainer,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.onInverseSurface,
      ),
      actionTextColor: colors.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColors.radiusSheet),
        ),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
  );
}
