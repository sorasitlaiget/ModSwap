import 'package:flutter/material.dart';

/// All possible notification categories for ModSwap.
/// 4 tabs total (Swap tab removed - no in-app swap request flow).
enum NotificationCategory {
  buyer,     // wishlist, rating, mark_sold_reminder
  forYou,    // price_drop, trending, new_item
  system,    // welcome, email_verified, security, password
}

/// All possible notification types (matches FCM payload "type" field).
enum NotificationType {
  // Buyer (seller-side activity)
  wishlist,
  ratingReceived,
  rateRequest,
  markSoldReminder,

  // For You (recommendations)
  priceDrop,
  trending,

  // System
  welcome,
  emailVerified,
  passwordChanged,
  securityAlert,
}

extension NotificationTypeProps on NotificationType {
  NotificationCategory get category {
    switch (this) {
      case NotificationType.wishlist:
      case NotificationType.ratingReceived:
      case NotificationType.rateRequest:
      case NotificationType.markSoldReminder:
        return NotificationCategory.buyer;
      case NotificationType.priceDrop:
      case NotificationType.trending:
        return NotificationCategory.forYou;
      case NotificationType.welcome:
      case NotificationType.emailVerified:
      case NotificationType.passwordChanged:
      case NotificationType.securityAlert:
        return NotificationCategory.system;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.wishlist:
        return Icons.favorite;
      case NotificationType.ratingReceived:
        return Icons.star;
      case NotificationType.rateRequest:
        return Icons.star_border;
      case NotificationType.markSoldReminder:
        return Icons.check_circle_outline;
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
        return const Color(0xFF10B981);
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

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? deepLinkTarget; // e.g. /item/123, /chat/456, /rating/789
  final Map<String, dynamic>? data; // additional FCM payload data

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.deepLinkTarget,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      deepLinkTarget: deepLinkTarget,
      data: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      if (deepLinkTarget != null) 'deepLinkTarget': deepLinkTarget,
      if (data != null) 'data': data,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? '';
    final type = NotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => NotificationType.welcome,
    );
    final createdAtRaw = map['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      // Firestore Timestamp
      createdAt = (createdAtRaw as dynamic).toDate() as DateTime;
    }
    return AppNotification(
      id: id,
      type: type,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: createdAt,
      isRead: map['isRead'] as bool? ?? false,
      deepLinkTarget: map['deepLinkTarget'] as String?,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  NotificationCategory get category => type.category;
  IconData get icon => type.icon;
  Color get color => type.color;

  /// Returns relative time string like "1 hour ago", "Yesterday 14:30"
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays == 1) {
      return 'Yesterday ${_formatTime(createdAt)}';
    }
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}