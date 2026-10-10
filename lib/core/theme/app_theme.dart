import 'package:flutter/material.dart';

/// Dnevni režim: bledo grimizno, bele pozadine, crna slova.
class AppColors {
  static const crimson = Color(0xFFB83B52); // naglasak
  static const crimsonPale = Color(
    0xFFFBE4E8,
  ); // pozadina čipova i istaknutih polja
  static const crimsonLine = Color(0xFFEBD3D8); // tanke ivice
  static const ink = Color(0xFF111111);
  static const inkSoft = Color(0xFF5B5558);
}

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.crimson,
    onPrimary: Colors.white,
    primaryContainer: AppColors.crimsonPale,
    onPrimaryContainer: Color(0xFF3B0A14),
    secondary: AppColors.crimson,
    surface: Colors.white,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkSoft,
    outline: Color(0xFF8C8185),
    outlineVariant: AppColors.crimsonLine,
    error: Color(0xFFB3261E),
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.crimsonLine),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.crimsonPale,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.crimson
              : AppColors.inkSoft,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: AppColors.ink,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.crimsonPale,
      selectedColor: AppColors.crimsonPale,
      side: BorderSide.none,
      labelStyle: const TextStyle(color: AppColors.ink, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.crimsonLine,
      space: 1,
    ),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
