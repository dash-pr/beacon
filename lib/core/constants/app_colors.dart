import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — deep indigo / slate
  static const Color primary = Color(0xFF6366F1);       // Indigo 500
  static const Color primaryContainer = Color(0xFF1E1B4B); // Indigo 950
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Surface palette — neutral dark
  static const Color background = Color(0xFF0F0F14);
  static const Color surface = Color(0xFF18181B);        // Zinc 900
  static const Color surfaceContainer = Color(0xFF27272A); // Zinc 800
  static const Color surfaceContainerHigh = Color(0xFF3F3F46); // Zinc 700
  static const Color outline = Color(0xFF3F3F46);

  // Semantic colors
  static const Color sosRed = Color(0xFFEF4444);
  static const Color urgentOrange = Color(0xFFF59E0B);
  static const Color safeGreen = Color(0xFF22C55E);
  static const Color warningYellow = Color(0xFFFACC15);
  static const Color info = Color(0xFF38BDF8);

  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);    // Zinc 50
  static const Color textSecondary = Color(0xFFA1A1AA);  // Zinc 400
  static const Color textMuted = Color(0xFF71717A);      // Zinc 500

  // Message bubbles
  static const Color messageSent = Color(0xFF4F46E5);    // Indigo 600
  static const Color messageReceived = Color(0xFF27272A);
  static const Color messageSos = Color(0xFF450A0A);

  // Legacy aliases for compatibility
  static const Color accent = primary;
  static const Color accentLight = info;
  static const Color surfaceLight = surfaceContainer;
}
