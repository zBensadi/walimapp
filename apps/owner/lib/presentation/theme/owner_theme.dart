import 'package:flutter/material.dart';

/// Reusable visual design tokens and ThemeData for the WalimApp Owner application.
///
/// Provides warm hospitality tones, WCAG AA compliant contrast, elegant typography,
/// and responsive touch-target ergonomics per FR-001 and FR-011.
class OwnerTheme {
  const OwnerTheme._();

  // --- Hospitality Brand Color Palette ---
  static const Color primaryBurgundy = Color(0xFF7B2036);
  static const Color primaryBurgundyDark = Color(0xFF561424);
  static const Color primaryBurgundyLight = Color(0xFFA53B55);
  static const Color accentGold = Color(0xFFC49A45);
  static const Color accentGoldLight = Color(0xFFE9D7A5);

  static const Color surfaceWarmLight = Color(0xFFFAF7F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardOutline = Color(0xFFE8E0DC);

  static const Color textPrimary = Color(0xFF231B1C);
  static const Color textSecondary = Color(0xFF6B5E5F);
  static const Color textMuted = Color(0xFF8C7E80);

  // --- Dimension & Spacing Tokens ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  static const double minTouchTarget = 48.0;

  /// Builds the light theme configured for cross-platform Android and Windows rendering.
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryBurgundy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF9E8EC),
      onPrimaryContainer: primaryBurgundyDark,
      secondary: accentGold,
      onSecondary: Colors.white,
      secondaryContainer: accentGoldLight,
      onSecondaryContainer: Color(0xFF4A3710),
      surface: surfaceWhite,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceWarmLight,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: cardOutline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceWarmLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: cardOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        elevation: 2,
        indicatorColor: colorScheme.primaryContainer,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryBurgundy,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceWhite,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: const IconThemeData(color: primaryBurgundy),
        unselectedIconTheme: const IconThemeData(color: textSecondary),
        selectedLabelTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primaryBurgundy,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
    );
  }
}
