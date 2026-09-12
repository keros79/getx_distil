import 'package:flutter/material.dart';

/// Light theme for the demo app.
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
}

/// Dark theme for the demo app.
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purpleAccent,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Colors.white10),
      ),
    ),
  );
}
