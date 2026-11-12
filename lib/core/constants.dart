import 'package:flutter/material.dart';

class AppConstants {
  // --- Modern Fintech Light Mode Palette ---
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFF1F5F9);
  static const Color bgDark = Color(0xFFF8FAFC);
  static const Color borderColor = Color(0xFFE2E8F0);

  // --- Typography Colors ---
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // --- Fintech Brand Accents ---
  static const Color accentGreen = Color(0xFF059669);
  static const Color accentGreenLight = Color(0xFFD1FAE5);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueLight = Color(0xFFDBEAFE);
  static const Color accentGold = Color(0xFFD97706);
  static const Color accentGoldLight = Color(0xFFFEF3C7);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color dangerRedLight = Color(0xFFFEE2E2);

  // --- API & Auth Credentials ---
  static const String baseUrl = "https://nexpay.vip/api/admin";
  static const String apiEndpoint = "$baseUrl/api.php";
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth Constants for Console Security & Handshake
  static const String adminSecret = "nexpay_super_secret_admin_token_2026";
  static const String defaultAdminUser = "root_admin";
  static const String defaultAdminPass = "admin123";

  // --- Shadows ---
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}