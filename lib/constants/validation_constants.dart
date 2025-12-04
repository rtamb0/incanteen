/// Validation constants used across the app
class ValidationConstants {
  /// Regular expression for validating email addresses
  static final RegExp emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  
  /// Minimum password length
  static const int minPasswordLength = 6;
}
