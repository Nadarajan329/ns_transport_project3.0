import 'package:flutter/material.dart';

/// Premium blue theme color constants for NS Transport.
///
/// Uses Material Design 3 color guidelines with a professional
/// blue palette suitable for a transport management system.
abstract final class AppColors {
  // ─── Primary Palette ───────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0); // Blue 800
  static const Color primaryLight = Color(0xFF42A5F5); // Blue 400
  static const Color primaryDark = Color(0xFF0D47A1); // Blue 900

  // ─── Surface & Background ─────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFF);
  static const Color background = Color(0xFFEFF3FB);
  static const Color card = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF5F7FA);

  // ─── Semantic Colors ──────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF0288D1);

  // ─── Text Colors ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF44474F);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // ─── Border & Divider ─────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // ─── Shadow ───────────────────────────────────────────────────────
  /// Blue-tinted shadow for elevated components.
  static const Color shadow = Color(0x1A1565C0);

  // ─── Gradient ─────────────────────────────────────────────────────
  static const Color gradientStart = Color(0xFF1565C0);
  static const Color gradientEnd = Color(0xFF0D47A1);

  /// Primary gradient used across app bars, buttons, and hero sections.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // ─── Status Colors ────────────────────────────────────────────────
  static const Color statusDraft = Color(0xFF78909C); // Blue Grey 400
  static const Color statusSubmitted = Color(0xFF1565C0); // Primary Blue
  static const Color statusApproved = Color(0xFF2E7D32); // Green 800
  static const Color statusRejected = Color(0xFFC62828); // Red 800
  static const Color statusInProgress = Color(0xFFF57C00); // Orange 700
  static const Color statusCompleted = Color(0xFF2E7D32); // Green 800
  static const Color statusCancelled = Color(0xFF757575); // Grey 600

  // ─── Status Color Helper ──────────────────────────────────────────

  /// Returns the appropriate color for a given trip/document status.
  ///
  /// Falls back to [textSecondary] for unrecognised statuses.
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return statusDraft;
      case 'submitted':
      case 'pending':
        return statusSubmitted;
      case 'approved':
        return statusApproved;
      case 'rejected':
        return statusRejected;
      case 'in_progress':
      case 'in progress':
        return statusInProgress;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      default:
        return textSecondary;
    }
  }

  // ─── Crypto Theme (Dark Mode) ─────────────────────────────────────
  static const Color cryptoBackground = Color(0xFF0B0E14);
  static const Color cryptoCard = Color(0xFF1E232F);
  static const Color neonCyan = Color(0xFF00E5FF);
}
