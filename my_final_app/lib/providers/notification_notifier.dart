import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'auth_notifier.dart';
import 'auth_provider.dart';

part 'notification_notifier.g.dart';

@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  final NotificationService _service = NotificationService();
  StreamSubscription<List<AppNotification>>? _sub;
  String? _currentUid;

  @override
  List<AppNotification> build() {
    ref.onDispose(() {
      _sub?.cancel();
    });

    final authData = ref.watch(authNotifierProvider);
    final uid = authData.status == AuthStatus.authenticated
        ? authData.firebaseUser?.uid
        : null;

    if (uid == null) {
      _sub?.cancel();
      _sub = null;
      _currentUid = null;
      return [];
    }

    if (uid != _currentUid) {
      _currentUid = uid;
      _sub?.cancel();
      _sub = _service.stream(uid).listen((list) {
        state = list;
      });
    }

    return [];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  Future<void> markRead(String id) async {
    if (_currentUid == null) return;
    await _service.markRead(_currentUid!, id);
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  Future<void> markAllRead() async {
    if (_currentUid == null) return;
    await _service.markAllRead(_currentUid!);
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  Future<void> delete(String id) async {
    if (_currentUid == null) return;
    state = state.where((n) => n.id != id).toList();
    await _service.delete(_currentUid!, id);
  }
}
