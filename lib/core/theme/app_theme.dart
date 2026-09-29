import 'package:flutter/material.dart';

class AppTheme {
  // Kindle Classic Sepia
  static final ThemeData sepiaTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFBF0D9),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF5F4B32),
      surface: Color(0xFFFBF0D9),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2C2214), height: 1.6),
    ),
  );

  // Day Light
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87, height: 1.6),
    ),
  );

  // Night Dark
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      surface: Color(0xFF1E1E1E),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0), height: 1.6),
    ),
  );
}