import 'package:flutter/material.dart';

/// Light mode color palette (default brand)
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF0066CC),
  onPrimary: Colors.white,
  secondary: Color(0xFF4D9DE0),
  onSecondary: Colors.white,
  background: Color(0xFFF5F7FA),
  onBackground: Colors.black87,
  surface: Colors.white,
  onSurface: Colors.black87,
  error: Color(0xFFD32F2F),
  onError: Colors.white,
);

/// Dark mode color palette
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF90CAF9),
  onPrimary: Colors.black,
  secondary: Color(0xFFBBDEFB),
  onSecondary: Colors.black,
  background: Color(0xFF121212),
  onBackground: Colors.white,
  surface: Color(0xFF1E1E1E),
  onSurface: Colors.white,
  error: Color(0xFFEF9A9A),
  onError: Colors.black,
);