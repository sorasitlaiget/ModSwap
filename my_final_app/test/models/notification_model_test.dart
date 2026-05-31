import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/models/notification_model.dart';

void main() {
  final baseNotif = AppNotification(
    id: 'notif1',
    type: NotificationType.welcome,
    title: 'Welcome!',
    body: 'Welcome to ModSwap',
    createdAt: DateTime(2025, 1, 1, 12, 0),
    isRead: false,
  );

  group('AppNotification.fromMap', () {
    test('parses basic fields', () {
      final map = {
        'type': 'welcome',
        'title': 'Welcome!',
        'body': 'Welcome to ModSwap',
        'createdAt': DateTime(2025, 1, 1, 12, 0).millisecondsSinceEpoch,
        'isRead': false,
      };
      final n = AppNotification.fromMap('notif1', map);
      expect(n.id, 'notif1');
      expect(n.type, NotificationType.welcome);
      expect(n.title, 'Welcome!');
      expect(n.isRead, false);
    });

    test('defaults to welcome type for unknown type string', () {
      final map = {
        'type': 'unknown_type',
        'title': 'Test',
        'body': 'Test',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
      };
      final n = AppNotification.fromMap('id', map);
      expect(n.type, NotificationType.welcome);
    });

    test('defaults isRead to false when missing', () {
      final map = {
        'type': 'welcome',
        'title': 'T',
        'body': 'B',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      final n = AppNotification.fromMap('id', map);
      expect(n.isRead, false);
    });
  });

  group('AppNotification.toMap', () {
    test('serializes all fields', () {
      final map = baseNotif.toMap();
      expect(map['type'], 'welcome');
      expect(map['title'], 'Welcome!');
      expect(map['isRead'], false);
    });

    test('excludes null deepLinkTarget', () {
      final map = baseNotif.toMap();
      expect(map.containsKey('deepLinkTarget'), false);
    });

    test('includes deepLinkTarget when set', () {
      final n = AppNotification(
        id: 'n2',
        type: NotificationType.wishlist,
        title: 'T',
        body: 'B',
        createdAt: DateTime.now(),
        deepLinkTarget: '/item/123',
      );
      expect(n.toMap()['deepLinkTarget'], '/item/123');
    });
  });

  group('AppNotification.copyWith', () {
    test('marks as read', () {
      final read = baseNotif.copyWith(isRead: true);
      expect(read.isRead, true);
      expect(read.id, baseNotif.id);
      expect(read.title, baseNotif.title);
    });
  });

  group('NotificationType category', () {
    test('wishlist belongs to buyer category', () {
      expect(NotificationType.wishlist.category, NotificationCategory.buyer);
    });

    test('priceDrop belongs to forYou category', () {
      expect(NotificationType.priceDrop.category, NotificationCategory.forYou);
    });

    test('welcome belongs to system category', () {
      expect(NotificationType.welcome.category, NotificationCategory.system);
    });

    test('securityAlert belongs to system category', () {
      expect(
        NotificationType.securityAlert.category,
        NotificationCategory.system,
      );
    });
  });

  group('AppNotification.timeAgo', () {
    test('returns Just now for recent notification', () {
      final recent = AppNotification(
        id: 'r',
        type: NotificationType.welcome,
        title: 'T',
        body: 'B',
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(recent.timeAgo, 'Just now');
    });

    test('returns minutes ago format', () {
      final n = AppNotification(
        id: 'r',
        type: NotificationType.welcome,
        title: 'T',
        body: 'B',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(n.timeAgo, '15 min ago');
    });

    test('returns hours ago format', () {
      final n = AppNotification(
        id: 'r',
        type: NotificationType.welcome,
        title: 'T',
        body: 'B',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(n.timeAgo, '3 hours ago');
    });
  });
}
