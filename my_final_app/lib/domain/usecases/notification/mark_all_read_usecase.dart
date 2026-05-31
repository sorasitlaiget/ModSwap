import '../../repositories/notification_repository.dart';

class MarkAllReadUseCase {
  final NotificationRepository _repo;
  const MarkAllReadUseCase(this._repo);
  Future<void> call(String uid) => _repo.markAllRead(uid);
}
