import 'package:flutter/material.dart';

class CognataColors {
  CognataColors._();

  static const cream = Color(0xFFFAF6EE);
  static const paper = Color(0xFFF3ECDD);
  static const ink = Color(0xFF1F1A14);
  static const faded = Color(0xFF6B6152);
  static const accent = Color(0xFF8C2F22);
  static const gold = Color(0xFFB08D3E);
  static const card = Color(0xFFFFFDF7);
  static const border = Color(0xFFE5DCC8);
  static const leafBorder = Color(0xFFD8CDB4);
  static const green = Color(0xFF15803D);
  static const greenSurface = Color(0xFFF0FDF4);
  static const greenInk = Color(0xFF166534);
}

class CognataFonts {
  CognataFonts._();

  static const display = 'PlayfairDisplay';
  static const body = 'Merriweather';
}

ThemeData buildCognataTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: CognataFonts.body,
    colorScheme: ColorScheme.fromSeed(seedColor: CognataColors.accent).copyWith(
      surface: CognataColors.cream,
      primary: CognataColors.accent,
      secondary: CognataColors.gold,
      onSurface: CognataColors.ink,
    ),
  );

  const rounded = BorderRadius.all(Radius.circular(10));

  return base.copyWith(
    scaffoldBackgroundColor: CognataColors.cream,
    dividerColor: CognataColors.border,
    textTheme: base.textTheme.apply(
      fontFamily: CognataFonts.body,
      bodyColor: CognataColors.ink,
      displayColor: CognataColors.ink,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: CognataColors.card,
      hintStyle: TextStyle(color: CognataColors.faded),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: BorderSide(color: CognataColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: BorderSide(color: CognataColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: BorderSide(color: CognataColors.gold, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: CognataColors.ink,
      contentTextStyle: TextStyle(
        fontFamily: CognataFonts.body,
        color: CognataColors.cream,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CognataColors.accent,
    ),
  );
}
