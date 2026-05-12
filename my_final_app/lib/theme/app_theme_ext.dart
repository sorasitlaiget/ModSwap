import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware color helpers — use these in widgets that need to respond
/// to dark mode. Brand colors (orange/navy headers, navy buttons) keep
/// their fixed hue in both themes; only "surface" colors swap.
///
/// Usage:
/// ```dart
/// Container(color: context.appBg)
/// Text('hi', style: TextStyle(color: context.primaryText))
/// ```
extension AppThemeExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// App / scaffold background (the page itself).
  Color get appBg =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF2F3F7);

  /// Card / surface background (white-ish in light, near-black in dark).
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  /// Secondary surface (e.g. a chip inside a card).
  Color get surfaceAlt =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6);

  /// Primary text color on the appBg / cardBg surface.
  Color get primaryText => isDark ? Colors.white : AppColors.navy;

  /// Muted / secondary text.
  Color get secondaryText =>
      isDark ? const Color(0xFFB0B0B0) : AppColors.textGray;

  /// Hairline divider color.
  Color get divider =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

  /// Subtle border / outline color around inputs/cards.
  Color get border =>
      isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
}
