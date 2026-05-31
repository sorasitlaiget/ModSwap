import '../entities/notification.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watch(String uid);
  Future<void> markRead(String uid, String notifId);
  Future<void> markAllRead(String uid);
  Future<void> delete(String uid, String notifId);
  Future<void> send({
    required String recipientUid,
    required NotificationType type,
    required String title,
    required String body,
    String? deepLinkTarget,
    Map<String, dynamic>? data,
  });
}
