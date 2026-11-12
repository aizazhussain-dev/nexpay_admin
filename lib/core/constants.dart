import 'package:flutter/material.dart';

class AppConstants {
  // --- Institutional Fintech Surface Palette (Stripe / Mercury Style) ---
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFF1F5F9);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // --- Executive Typography Colors ---
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // --- Refined Fintech Accents ---
  static const Color accentGreen = Color(0xFF059669);
  static const Color accentGreenLight = Color(0xFFECFDF5);
  static const Color accentBlue = Color(0xFF1D4ED8);
  static const Color accentBlueLight = Color(0xFFEFF6FF);
  static const Color accentGold = Color(0xFFB45309);
  static const Color accentGoldLight = Color(0xFFFFFBEB);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color dangerRedLight = Color(0xFFFEF2F2);

  // --- Live Hostinger API & Auth Credentials ---
  static const String baseUrl = "https://smartvest.tech";
  static const String apiEndpoint = "https://smartvest.tech/api.php";
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Server Master Key & Admin Console Login
  static const String adminSecret = "NexPay_Master_Admin_Sec_#2026";
  static const String defaultAdminUser = "aizaz_admin";
  static const String defaultAdminPass = "NexPay@2026";

  // --- Subtle Institutional Elevation ---
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}