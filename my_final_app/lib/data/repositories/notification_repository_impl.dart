import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _ds;
  NotificationRepositoryImpl(this._ds);

  @override
  Stream<List<AppNotification>> watch(String uid) => _ds.watch(uid);

  @override
  Future<void> markRead(String uid, String notifId) =>
      _ds.markRead(uid, notifId);

  @override
  Future<void> markAllRead(String uid) => _ds.markAllRead(uid);

  @override
  Future<void> delete(String uid, String notifId) => _ds.delete(uid, notifId);

  @override
  Future<void> send({
    required String recipientUid,
    required NotificationType type,
    required String title,
    required String body,
    String? deepLinkTarget,
    Map<String, dynamic>? data,
  }) =>
      _ds.send(
        recipientUid: recipientUid,
        type: type,
        title: title,
        body: body,
        deepLinkTarget: deepLinkTarget,
        data: data,
      );
}
