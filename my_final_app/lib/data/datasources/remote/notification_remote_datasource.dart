import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/notification.dart';

class NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;

  NotificationRemoteDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  Stream<List<AppNotification>> watch(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList());
  }

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

  Future<void> delete(String uid, String notifId) async {
    await _col(uid).doc(notifId).delete();
  }
}
