import 'package:flutter/material.dart';

class AdminColors {
  static const Color page = Color(0xFF08111F);
  static const Color panel = Color(0xFF0F1D31);
  static const Color panelStrong = Color(0xFF10233B);
  static const Color panelSoft = Color(0xFF0D1C30);
  static const Color border = Color(0xFF213B5B);
  static const Color borderBright = Color(0xFF315B84);
  static const Color muted = Color(0xFF8EA6C1);
  static const Color text = Color(0xFFEDF4FF);

  static const Color accent = Color(0xFF62D8FF);
  static const Color accentStrong = Color(0xFF2F9DD2);
  static const Color success = Color(0xFF68E0AC);
  static const Color warning = Color(0xFFFFD37B);
  static const Color danger = Color(0xFFFF91A3);

  static const Color cardBg = Color(0xFF0F1D31);
  static const Color inputBg = Color(0xFF091727);
  static const Color chipBg = Color(0xFF12334A);
}

class AdminTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.page,
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.accent,
        onPrimary: Color(0xFF071422),
        secondary: AdminColors.accentStrong,
        surface: AdminColors.panel,
        error: AdminColors.danger,
      ),
      cardTheme: CardThemeData(
        color: AdminColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AdminColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.borderBright),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.borderBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.accent, width: 2),
        ),
        hintStyle: const TextStyle(color: AdminColors.muted, fontSize: 13),
        labelStyle: const TextStyle(color: AdminColors.muted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.accentStrong,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.text,
          side: const BorderSide(color: AdminColors.borderBright),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AdminColors.text, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AdminColors.text, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(color: AdminColors.muted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: AdminColors.text, fontSize: 13),
        bodySmall: TextStyle(color: AdminColors.muted, fontSize: 12),
      ),
    );
  }
}
