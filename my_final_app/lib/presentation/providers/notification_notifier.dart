import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/notification/mark_all_read_usecase.dart';
import '../../domain/usecases/notification/mark_read_usecase.dart';
import '../../domain/usecases/notification/watch_notifications_usecase.dart';
import '../../presentation/di/providers.dart';
import 'auth_notifier.dart';
import 'auth_provider.dart';

part 'notification_notifier.g.dart';

@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  late WatchNotificationsUseCase _watch;
  late MarkReadUseCase _markRead;
  late MarkAllReadUseCase _markAllRead;

  StreamSubscription<List<AppNotification>>? _sub;
  String? _currentUid;

  @override
  List<AppNotification> build() {
    _watch = ref.read(watchNotificationsUseCaseProvider);
    _markRead = ref.read(markReadUseCaseProvider);
    _markAllRead = ref.read(markAllReadUseCaseProvider);

    ref.onDispose(() => _sub?.cancel());

    final authData = ref.watch(authNotifierProvider);
    final uid = authData.status == AuthStatus.authenticated ? authData.uid : null;

    if (uid == null) {
      _sub?.cancel();
      _sub = null;
      _currentUid = null;
      return [];
    }

    if (uid != _currentUid) {
      _currentUid = uid;
      _sub?.cancel();
      _sub = _watch(uid).listen((list) => state = list);
    }

    return [];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  Future<void> markRead(String id) async {
    if (_currentUid == null) return;
    await _markRead(_currentUid!, id);
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  Future<void> markAllRead() async {
    if (_currentUid == null) return;
    await _markAllRead(_currentUid!);
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  Future<void> delete(String id) async {
    if (_currentUid == null) return;
    state = state.where((n) => n.id != id).toList();
    await ref.read(notificationRepositoryProvider).delete(_currentUid!, id);
  }
}
