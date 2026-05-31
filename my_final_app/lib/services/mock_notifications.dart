import '../domain/entities/notification.dart';

/// Mock notification data for frontend development.
/// Replace with Firestore stream from `users/{userId}/notifications/` later.
class MockNotifications {
  static List<AppNotification> getAll() {
    final now = DateTime.now();
    return [
      // ========== TODAY ==========
      AppNotification(
        id: 'n1',
        type: NotificationType.wishlist,
        title: 'Someone Wishlisted Your Item',
        body: '3 people added "Used iPad GEN 11" to wishlist',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
        deepLinkTarget: '/item/ipad-gen-11',
        data: {'itemId': 'ipad-gen-11', 'count': 3},
      ),
      AppNotification(
        id: 'n2',
        type: NotificationType.ratingReceived,
        title: 'New Rating Received',
        body: 'Tar rated you 5 stars: "Great seller!"',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: false,
        deepLinkTarget: '/profile/me/ratings',
        data: {'stars': 5, 'reviewerId': 'tar_uid'},
      ),
      AppNotification(
        id: 'n3',
        type: NotificationType.rateRequest,
        title: 'Rate Your Experience',
        body: '@veerachai marked your deal complete. Rate them!',
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
        deepLinkTarget: '/rating/txn_xyz',
        data: {'transactionId': 'txn_xyz', 'sellerId': 'veerachai_uid'},
      ),

      // ========== YESTERDAY ==========
      AppNotification(
        id: 'n4',
        type: NotificationType.priceDrop,
        title: 'Price Drop on Wishlist',
        body: '"Engineering Workshop" is now 250 THB (was 350)',
        createdAt: now.subtract(const Duration(days: 1, hours: 9)),
        isRead: true,
        deepLinkTarget: '/item/engineering-workshop',
        data: {'oldPrice': 350, 'newPrice': 250},
      ),
      AppNotification(
        id: 'n5',
        type: NotificationType.trending,
        title: 'Hot Items in Your Category',
        body: '5 trending textbooks you might like',
        createdAt: now.subtract(const Duration(days: 1, hours: 13)),
        isRead: true,
        deepLinkTarget: '/category/textbooks?filter=trending',
      ),
      AppNotification(
        id: 'n6',
        type: NotificationType.markSoldReminder,
        title: 'Deal Complete!',
        body: '"Apple Pencil" has been marked as sold.',
        createdAt: now.subtract(const Duration(days: 1, hours: 18)),
        isRead: true,
        deepLinkTarget: '/my-items/apple-pencil',
      ),

      // ========== EARLIER ==========
      AppNotification(
        id: 'n7',
        type: NotificationType.welcome,
        title: 'Welcome to ModSwap!',
        body: 'Start buying, selling, and swapping with KMUTT',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        deepLinkTarget: '/onboarding',
      ),
      AppNotification(
        id: 'n8',
        type: NotificationType.emailVerified,
        title: 'Email Verified',
        body: 'Your @mail.kmutt.ac.th account is now verified',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      AppNotification(
        id: 'n10',
        type: NotificationType.passwordChanged,
        title: 'Password Changed',
        body: 'Your password was changed at 14:30',
        createdAt: now.subtract(const Duration(days: 5)),
        isRead: true,
        deepLinkTarget: '/settings/security',
      ),
      AppNotification(
        id: 'n11',
        type: NotificationType.securityAlert,
        title: 'New Login Detected',
        body: 'Login from new device. If not you, secure your account.',
        createdAt: now.subtract(const Duration(days: 6)),
        isRead: true,
        deepLinkTarget: '/security',
      ),
    ];
  }

  /// Filter by category. Pass `null` to get all.
  static List<AppNotification> getByCategory(NotificationCategory? cat) {
    final all = getAll();
    if (cat == null) return all;
    return all.where((n) => n.category == cat).toList();
  }

  /// Group notifications by date label (Today, Yesterday, Earlier).
  static Map<String, List<AppNotification>> groupByDate(
    List<AppNotification> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final n in items) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        todayItems.add(n);
      } else if (d == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlier.add(n);
      }
    }

    final result = <String, List<AppNotification>>{};
    if (todayItems.isNotEmpty) result['TODAY'] = todayItems;
    if (yesterdayItems.isNotEmpty) result['YESTERDAY'] = yesterdayItems;
    if (earlier.isNotEmpty) result['EARLIER'] = earlier;
    return result;
  }

  static int unreadCount() {
    return getAll().where((n) => !n.isRead).length;
  }
}
