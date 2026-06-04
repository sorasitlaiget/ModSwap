import '../../entities/notification.dart';
import '../../repositories/notification_repository.dart';

class WatchNotificationsUseCase {
  final NotificationRepository _repo;
  const WatchNotificationsUseCase(this._repo);
  Stream<List<AppNotification>> call(String uid) => _repo.watch(uid);
}
