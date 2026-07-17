import 'package:flutter/material.dart';

/// Smittenbrot brand colors
class AppColors {
  AppColors._();

  // Primary - warm brown tones for bakery
  static const primary = Color(0xFF5C3A1E);        // Dark bread brown
  static const primaryLight = Color(0xFF8B6914);    // Golden crust
  static const primaryDark = Color(0xFF3E2410);     // Deep roast

  // Accent
  static const accent = Color(0xFFC4956A);          // Warm caramel
  static const accentLight = Color(0xFFE8D5B7);     // Light dough

  // Background
  static const background = Color(0xFFFDF8F0);      // Warm cream
  static const surface = Color(0xFFFFFBF5);         // White-warm
  static const surfaceDark = Color(0xFFF5EDE0);     // Slightly darker cream

  // Text
  static const textPrimary = Color(0xFF2C1810);     // Dark brown
  static const textSecondary = Color(0xFF7A6A5A);   // Muted brown
  static const textOnPrimary = Color(0xFFFFFBF5);   // Light on dark bg
  static const textHint = Color(0xFFB8A89A);        // Light brown hint

  // Functional
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFFFA726);
  static const info = Color(0xFF42A5F5);

  // Product category colors
  static const categorySourdough = Color(0xFF8D6E63);
  static const categoryBaguette = Color(0xFFD4A56A);
  static const categoryBrioche = Color(0xFFE8B88A);
  static const categoryCiabatta = Color(0xFFBCAAA4);
  static const categoryFocaccia = Color(0xFFA5D6A7);
}
