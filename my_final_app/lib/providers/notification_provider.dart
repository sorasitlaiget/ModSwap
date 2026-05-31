import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  StreamSubscription<List<AppNotification>>? _sub;
  String? _uid;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void init(String uid) {
    if (_uid == uid) return; // already listening for this user
    _uid = uid;
    _sub?.cancel();
    _sub = _service.stream(uid).listen((list) {
      _notifications = list;
      notifyListeners();
    });
  }

  void clear() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    _notifications = [];
    notifyListeners();
  }

  Future<void> markRead(String notifId) async {
    if (_uid == null) return;
    await _service.markRead(_uid!, notifId);
    // Optimistic update
    _notifications = _notifications
        .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (_uid == null) return;
    await _service.markAllRead(_uid!);
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  Future<void> delete(String notifId) async {
    if (_uid == null) return;
    _notifications = _notifications.where((n) => n.id != notifId).toList();
    notifyListeners();
    await _service.delete(_uid!, notifId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
