import 'package:flutter/material.dart';

class AppColors {
  // App Blue Gradient (1=darkest, 10=lightest)
  static const Color blue1 = Color(0xFF101D45);
  static const Color blue2 = Color(0xFF15275D);
  static const Color blue3 = Color(0xFF1A3174);
  static const Color blue4 = Color(0xFF203A8B);
  static const Color blue5 = Color(0xFF2544A2);
  static const Color blue6 = Color(0xFF2D53C6);
  static const Color blue7 = Color(0xFF4A6DD6);
  static const Color blue8 = Color(0xFF6E8ADE);
  static const Color blue9 = Color(0xFF92A7E6);
  static const Color blue10 = Color(0xFFB7C5EF);

  // Primary Colors
  static const Color primary = blue5;
  static const Color primaryDark = blue3;
  static const Color primaryLight = blue8;

  // Sensor Colors - Temperature
  static const Color temperatureSoft = Color(0xFFFFEDE1);
  static const Color temperatureMedium = Color(0xFFFFC9A6);
  static const Color temperatureDark = Color(0xFFFF6F4E);

  // Sensor Colors - pH
  static const Color phSoft = Color(0xFFF3F1FF);
  static const Color phMedium = Color(0xFFD7C9FF);
  static const Color phDark = Color(0xFF8A63D2);

  // Sensor Colors - Turbidity
  static const Color turbiditySoft = Color(0xFFFFF6E6);
  static const Color turbidityMedium = Color(0xFFFFD88F);
  static const Color turbidityDark = Color(0xFFF5A623);

  // Sensor Colors - Dissolved Oxygen
  static const Color doSoft = Color(0xFFE6FBF1);
  static const Color doMedium = Color(0xFFB2EBD9);
  static const Color doDark = Color(0xFF2BAE66);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Offline Warning
  static const Color offlineBackground = Color(0xFFFFEBEE);
  static const Color offlineText = Color(0xFFD32F2F);

  // Card Shadows
  static const Color shadowColor = Color(0x1A000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blue3, blue6],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Colors.white, blue8],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
