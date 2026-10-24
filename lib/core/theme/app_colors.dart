import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF4338CA);
  static const primaryDark = Color(0xFF312E81);
  static const primarySoft = Color(0xFFEEF0FF);
  static const violet = Color(0xFF7C3AED);

  static const aqua = Color(0xFF06B6D4);
  static const aquaSoft = Color(0xFFE6FAFD);
  static const mint = Color(0xFF10B981);
  static const mintSoft = Color(0xFFE8F9F1);

  static const background = Color(0xFFF4F5FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F8FC);
  static const border = Color(0xFFECEEF6);

  static const text = Color(0xFF171A2B);
  static const muted = Color(0xFF6B7280);
  static const soft = Color(0xFF8A90A6);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE11D48);
  static const info = Color(0xFF06B6D4);
  static const dangerSoft = Color(0xFFFDECF0);
  static const warningSoft = Color(0xFFFFF6E5);

  static const radiusCard = 22.0;
  static const radiusInput = 15.0;
  static const radiusSheet = 30.0;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF6D28D9)],
    stops: [0, 0.52, 1],
  );

  static const pointsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF7C3AED)],
    stops: [0, 0.58, 1],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
  );

  static const cardShadow = [
    BoxShadow(color: Color(0x171E1B4B), blurRadius: 28, offset: Offset(0, 10)),
  ];

  static const softShadow = [
    BoxShadow(color: Color(0x0D1E1B4B), blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const elevatedShadow = [
    BoxShadow(color: Color(0x241E1B4B), blurRadius: 36, offset: Offset(0, 16)),
  ];
}
