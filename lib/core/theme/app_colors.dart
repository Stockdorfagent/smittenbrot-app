import 'package:flutter/material.dart';

/// Smittenbrot brand colors — matching website exactly.
class AppColors {
  AppColors._();

  // Brand — matching website
  static const primary = Color(0xFFf8120e);        // smitten-primary (red)
  static const primaryLight = Color(0xFFf8120e);    // same red
  static const primaryDark = Color(0xFFc00e0b);     // darker red

  // Accent
  static const accent = Color(0xFFf8120e);          // same as primary on website
  static const accentLight = Color(0xFFF3F4F6);     // light grey

  // Background
  static const background = Color(0xFFFFFFFF);      // white
  static const surface = Color(0xFFFFFFFF);         // white
  static const surfaceDark = Color(0xFFE5E7EB);     // border grey

  // Text
  static const textPrimary = Color(0xFF1A1A1A);     // dark text
  static const textSecondary = Color(0xFF6B7280);   // secondary grey
  static const textOnPrimary = Color(0xFFFFFFFF);   // white on red
  static const textHint = Color(0xFF9CA3AF);        // lighter grey

  // Functional
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFFFA726);
  static const info = Color(0xFF42A5F5);

  // Product card colors (deterministic from product id)
  static const productColors = [
    Color(0xFF8B5E3C),
    Color(0xFF6B8E4E),
    Color(0xFFC17A2B),
    Color(0xFF7B5B3A),
    Color(0xFFA0522D),
  ];

  // Category colors (kept for order timeline compatibility)
  static const categorySourdough = Color(0xFF8B5E3C);
  static const categoryBaguette = Color(0xFFD4A56A);
  static const categoryBrioche = Color(0xFFE8B88A);
  static const categoryCiabatta = Color(0xFFBCAAA4);
  static const categoryFocaccia = Color(0xFFA5D6A7);
}
