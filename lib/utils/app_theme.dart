import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF5F7FB);
  static const surface = Colors.white;
  static const ink = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const softText = Color(0xFF475467);
  static const line = Color(0xFFE4E7EC);
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const purple = Color(0xFF7C3AED);
  static const teal = Color(0xFF0F766E);
  static const cyan = Color(0xFF0891B2);
  static const rose = Color(0xFFE11D48);
  static const amber = Color(0xFFF59E0B);
  static const indigo = Color(0xFF4F46E5);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const calm = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const trust = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const premium = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const fresh = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF0F766E), Color(0xFF84CC16)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warm = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFE11D48), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x120F172A), blurRadius: 22, offset: Offset(0, 10)),
  ];

  static const lift = [
    BoxShadow(color: Color(0x1A2563EB), blurRadius: 18, offset: Offset(0, 10)),
  ];

  static const glow = [
    BoxShadow(color: Color(0x242563EB), blurRadius: 26, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x147C3AED), blurRadius: 34, offset: Offset(0, 20)),
  ];
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.ink,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(
        color: AppColors.softText,
        fontSize: 14,
        height: 1.35,
      ),
      labelLarge: TextStyle(fontWeight: FontWeight.w800),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Color(0xFFFDFEFF),
      foregroundColor: AppColors.ink,
      surfaceTintColor: AppColors.surface,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: AppColors.surface,
      elevation: 0,
      indicatorColor: const Color(0xFFE0EAFF),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
    ),
  );
}
