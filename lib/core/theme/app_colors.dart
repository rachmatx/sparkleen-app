import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0D63D8);
  static const link = Color(0xFF0B56C2);
  static const backgroundDark = Color(0xFF0B1220);
  static const primaryDark = Color(0xFF084FAF);
  static const primarySoft = Color(0xFFE4EDFA);
  static const background = Color(0xFFEDF3FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE1EBF5);
  static const border = Color(0xFFC6D2E0);
  static const text = Color(0xFF102A43);
  static const muted = Color(0xFF40536A);
  static const soft = Color(0xFF74869C);
  static const success = Color(0xFF08745D);
  static const warning = Color(0xFF875400);
  static const danger = Color(0xFFBE2647);
  static const dangerSoft = Color(0xFFFCE8EE);
  static const warningSoft = Color(0xFFFFF1D7);
  static const mintSoft = Color(0xFFDDF2E9);

  static const radiusCard = 18.0;
  static const radiusInput = 12.0;
  static const radiusSheet = 30.0;

  static const cardShadow = [
    BoxShadow(color: Color(0x0C183A60), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const softShadow = [
    BoxShadow(color: Color(0x08183A60), blurRadius: 14, offset: Offset(0, 4)),
  ];
  static const elevatedShadow = [
    BoxShadow(color: Color(0x15183A60), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
