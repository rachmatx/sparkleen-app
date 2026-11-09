import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0D63D8);
  static const primaryDark = Color(0xFF084FAF);
  static const primarySoft = Color(0xFFDCEBFC);
  static const background = Color(0xFFE9F1F8);
  static const surface = Color(0xFFF8FBFF);
  static const surfaceMuted = Color(0xFFE1EBF5);
  static const border = Color(0xFFD0DDEB);
  static const text = Color(0xFF0A1B30);
  static const muted = Color(0xFF52657B);
  static const soft = Color(0xFF60758C);
  static const success = Color(0xFF08745D);
  static const warning = Color(0xFF875400);
  static const danger = Color(0xFFBE2647);
  static const dangerSoft = Color(0xFFFCE8EE);
  static const warningSoft = Color(0xFFFFF1D7);
  static const mintSoft = Color(0xFFDDF2E9);

  static const radiusCard = 22.0;
  static const radiusInput = 15.0;
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
