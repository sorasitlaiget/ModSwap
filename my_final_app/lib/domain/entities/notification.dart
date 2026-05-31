// Domain entity — pure Dart, zero Flutter/Firebase imports
// Note: NotificationTypeProps (IconData/Color) lives in presentation/theme/

enum NotificationCategory { buyer, forYou, system }

enum NotificationType {
  wishlist,
  markSoldReminder,
  ratingReceived,
  rateRequest,
  priceDrop,
  trending,
  welcome,
  emailVerified,
  passwordChanged,
  securityAlert,
}

extension NotificationTypeCategory on NotificationType {
  NotificationCategory get category {
    switch (this) {
      case NotificationType.wishlist:
      case NotificationType.markSoldReminder:
      case NotificationType.ratingReceived:
      case NotificationType.rateRequest:
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
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? deepLinkTarget;
  final Map<String, dynamic>? data;

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

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isRead': isRead,
    if (deepLinkTarget != null) 'deepLinkTarget': deepLinkTarget,
    if (data != null) 'data': data,
  };

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? '';
    final type = NotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => NotificationType.welcome,
    );
    final createdAtRaw = map['createdAt'];
    final DateTime createdAt;
    if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      // Firestore Timestamp — handled via dynamic, no firebase import needed
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

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays == 1) return 'Yesterday ${_fmt(createdAt)}';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
