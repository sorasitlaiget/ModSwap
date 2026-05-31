import 'package:flutter/material.dart';
import '../../domain/entities/notification.dart';

extension NotificationTypeTheme on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.wishlist:
        return Icons.favorite;
      case NotificationType.markSoldReminder:
        return Icons.check_circle;
      case NotificationType.ratingReceived:
        return Icons.star;
      case NotificationType.rateRequest:
        return Icons.star_border;
      case NotificationType.priceDrop:
        return Icons.trending_down;
      case NotificationType.trending:
        return Icons.local_fire_department;
      case NotificationType.welcome:
        return Icons.celebration;
      case NotificationType.emailVerified:
        return Icons.mark_email_read;
      case NotificationType.passwordChanged:
        return Icons.lock_outline;
      case NotificationType.securityAlert:
        return Icons.warning_amber;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.wishlist:
        return const Color(0xFFE11D48);
      case NotificationType.ratingReceived:
      case NotificationType.trending:
        return const Color(0xFFFFA000);
      case NotificationType.rateRequest:
      case NotificationType.welcome:
        return const Color(0xFFFA4616);
      case NotificationType.markSoldReminder:
      case NotificationType.priceDrop:
      case NotificationType.emailVerified:
        return const Color(0xFF10B981);
      case NotificationType.passwordChanged:
        return const Color(0xFF3B82F6);
      case NotificationType.securityAlert:
        return const Color(0xFFEF4444);
    }
  }
}

extension AppNotificationTheme on AppNotification {
  IconData get icon => type.icon;
  Color get color => type.color;
}
