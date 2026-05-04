import 'package:flutter/material.dart';

/// Centralized color palette for ModSwap.
/// Use AppColors.* anywhere — never hardcode hex values in widgets.
class AppColors {
  AppColors._();

  // Brand
  static const Color orange = Color(0xFFFA4616);
  static const Color navy = Color(0xFF091057);

  // Status
  static const Color badgeRed = Color(0xFFE24B4A);
  static const Color logoutRed = Color(0xFFEF4444);
  static const Color logoutBg = Color(0xFFFEF2F2);
  static const Color logoutBorder = Color(0xFFFECACA);

  // Neutrals
  static const Color softGray = Color(0xFFF3F4F6);
  static const Color textGray = Color(0xFF6B7280);
  static const Color unreadBg = Color(0xFFFFF7F2);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
}
