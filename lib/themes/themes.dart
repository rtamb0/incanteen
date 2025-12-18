import 'package:flutter/material.dart';
import 'package:incanteen/constants/style/style_constants.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  
  // ColorScheme from seed for Material 3 compatibility
  colorScheme: ColorScheme.fromSeed(
    seedColor: StyleConstants.colorOfApp,
    brightness: Brightness.light,
  ),
  
  // Legacy compatibility
  primaryColor: StyleConstants.colorOfApp,
  scaffoldBackgroundColor: StyleConstants.scaffoldBackgroundColor,
  
  // Text theme with colorTitle for body and display colors
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: StyleConstants.colorTitle),
    bodyMedium: TextStyle(color: StyleConstants.colorTitle),
    bodySmall: TextStyle(color: StyleConstants.colorTitle),
    displayLarge: TextStyle(color: StyleConstants.colorTitle),
    displayMedium: TextStyle(color: StyleConstants.colorTitle),
    displaySmall: TextStyle(color: StyleConstants.colorTitle),
  ),
  
  // TextButton theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: StyleConstants.colorOfApp,
    ),
  ),
  
  // ElevatedButton theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: StyleConstants.colorOfApp,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
