import 'package:flutter/material.dart';
import 'package:incanteen/themes/themes.dart';

/// Manages the application theme state and notifies listeners of theme changes.
///
/// This notifier allows runtime theme updates and supports hot-reload behavior.
/// Widgets can listen to theme changes using Provider.of<ThemeNotifier>(context).
class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData = buildAppTheme();

  /// Returns the current theme data.
  ThemeData get themeData => _themeData;

  /// Sets the theme to the default app theme.
  void setAppTheme() {
    _themeData = buildAppTheme();
    notifyListeners();
  }

  /// Sets a custom theme.
  ///
  /// This allows for runtime theme customization while maintaining
  /// the centralized theming architecture.
  void setCustomTheme(ThemeData newTheme) {
    _themeData = newTheme;
    notifyListeners();
  }
}
