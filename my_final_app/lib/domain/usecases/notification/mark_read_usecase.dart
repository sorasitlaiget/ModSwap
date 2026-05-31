import '../../repositories/notification_repository.dart';

class MarkReadUseCase {
  final NotificationRepository _repo;
  const MarkReadUseCase(this._repo);
  Future<void> call(String uid, String notifId) => _repo.markRead(uid, notifId);
}
