import 'package:flutter/material.dart';
import 'package:incanteen/constants/style/style_constants.dart';

/// Builds the app theme using Material 3 design.
///
/// This function centralizes all theme configuration and uses ColorScheme.fromSeed
/// to ensure consistent color relationships throughout the app.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,

    // ColorScheme from seed for Material 3 compatibility
    colorScheme: ColorScheme.fromSeed(
      seedColor: StyleConstants.colorOfApp,
      brightness: Brightness.light,
    ),

    // Legacy compatibility
    primaryColor: StyleConstants.colorOfApp,
    scaffoldBackgroundColor: StyleConstants.scaffoldBackgroundColor,

    // Text theme using Typography.material2021 with colorTitle applied
    textTheme: Typography.material2021().black.apply(
      displayColor: StyleConstants.colorTitle,
      bodyColor: StyleConstants.colorTitle,
    ),

    // TextButton theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: StyleConstants.colorOfApp),
    ),

    // ElevatedButton theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: StyleConstants.colorOfApp,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // OutlinedButton theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StyleConstants.colorOfApp,
        side: const BorderSide(color: StyleConstants.colorOfApp),
      ),
    ),
  );
}
