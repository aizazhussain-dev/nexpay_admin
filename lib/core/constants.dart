import 'package:flutter/material.dart';

/// Global Light / Dark Theme Controller (Defaults to Light Mode)
class NexPayThemeController extends ChangeNotifier {
  NexPayThemeController._();
  static final NexPayThemeController instance = NexPayThemeController._();

  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
  }
}

class AppConstants {
  static bool get isDark => NexPayThemeController.instance.isDark;

  // --- Institutional Fintech Surface Palette (Adaptive Light / Dark) ---
  static Color get background =>
      isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);

  static Color get surface =>
      isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);

  static Color get surfaceCard =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

  static Color get bgDark =>
      isDark ? const Color(0xFF060911) : const Color(0xFF0F172A);

  static Color get borderColor =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

  static Color get borderStrong =>
      isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

  // --- Executive Typography Colors ---
  static Color get textPrimary =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  static Color get textSecondary =>
      isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

  static Color get textMuted =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color get textLight =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // --- Refined Fintech Accents ---
  static Color get accentGreen =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

  static Color get accentGreenLight => isDark
      ? const Color(0xFF064E3B).withValues(alpha: 0.45)
      : const Color(0xFFECFDF5);

  static Color get accentBlue =>
      isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);

  static Color get accentBlueLight => isDark
      ? const Color(0xFF1E3A8A).withValues(alpha: 0.45)
      : const Color(0xFFEFF6FF);

  static Color get accentGold =>
      isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);

  static Color get accentGoldLight => isDark
      ? const Color(0xFF78350F).withValues(alpha: 0.45)
      : const Color(0xFFFFFBEB);

  static Color get dangerRed =>
      isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);

  static Color get dangerRedLight => isDark
      ? const Color(0xFF7F1D1D).withValues(alpha: 0.45)
      : const Color(0xFFFEF2F2);

  // --- Live Hostinger API & Auth Credentials (Unchanged) ---
  static const String baseUrl = "https://smartvest.tech";
  static const String apiEndpoint = "https://smartvest.tech/api.php";
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Server Master Key & Admin Console Login
  static const String adminSecret = "NexPay_Master_Admin_Sec_#2026";
  static const String defaultAdminUser = "aizaz_admin";
  static const String defaultAdminPass = "NexPay@2026";

  // --- Subtle Institutional Elevation ---
  static List<BoxShadow> get cardShadow => isDark
      ? [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ]
      : [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.035),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}