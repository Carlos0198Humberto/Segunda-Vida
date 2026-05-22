import 'package:flutter/material.dart';

class AppColors {
  // Primary brand
  static const Color primary = Color(0xFF6B4EFF);
  static const Color primaryLight = Color(0xFF8F76FF);
  static const Color primaryDark = Color(0xFF4B2EDF);

  // Secondary
  static const Color secondary = Color(0xFF00D4AA);
  static const Color secondaryLight = Color(0xFF33DDBB);
  static const Color secondaryDark = Color(0xFF00A882);

  // Accent
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentGold = Color(0xFFFFD700);

  // Surfaces — Light
  static const Color surfaceLight = Color(0xFFF8F7FF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF2F0FF);

  // Surfaces — Dark
  static const Color surfaceDark = Color(0xFF1A1625);
  static const Color cardDark = Color(0xFF231E35);
  static const Color backgroundDark = Color(0xFF120F1E);

  // Text
  static const Color textPrimary = Color(0xFF1A1625);
  static const Color textSecondary = Color(0xFF6B6580);
  static const Color textHint = Color(0xFFADA8C3);
  static const Color textOnDark = Color(0xFFF0EEF8);

  // Status
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF4D6D);
  static const Color info = Color(0xFF0984E3);

  // Categories
  static const Color categoryFood = Color(0xFFFF6B6B);
  static const Color categoryTransport = Color(0xFF4ECDC4);
  static const Color categoryHealth = Color(0xFF96CEB4);
  static const Color categoryEducation = Color(0xFFFFD700);
  static const Color categoryEntertainment = Color(0xFFDDA0DD);
  static const Color categoryShopping = Color(0xFFF0A500);
  static const Color categoryOther = Color(0xFFB2BEC3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient savingsGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF0984E3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunriseGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
