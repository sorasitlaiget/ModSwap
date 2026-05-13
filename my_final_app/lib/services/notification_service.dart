import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  // ─── Real-time stream ────────────────────────────────────────────────────

  Stream<List<AppNotification>> stream(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  Future<void> send({
    required String recipientUid,
    required NotificationType type,
    required String title,
    required String body,
    String? deepLinkTarget,
    Map<String, dynamic>? data,
  }) async {
    final notif = AppNotification(
      id: '',
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      deepLinkTarget: deepLinkTarget,
      data: data,
    );
    await _col(recipientUid).add({
      ...notif.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Mark as read ────────────────────────────────────────────────────────

  Future<void> markRead(String uid, String notifId) async {
    await _col(uid).doc(notifId).update({'isRead': true});
  }

  Future<void> markAllRead(String uid) async {
    final batch = _firestore.batch();
    final snap = await _col(uid).where('isRead', isEqualTo: false).get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  Future<void> delete(String uid, String notifId) async {
    await _col(uid).doc(notifId).delete();
  }
}
