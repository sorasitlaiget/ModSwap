import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_remote_datasource.dart';
import '../../../domain/entities/notification.dart';

class RatingRemoteDataSource {
  final FirebaseFirestore _firestore;
  final NotificationRemoteDataSource _notifDs;

  RatingRemoteDataSource(this._firestore, this._notifDs);

  Stream<List<Map<String, dynamic>>> watchPendingRatings(String uid) {
    return _firestore
        .collection('pendingRatings')
        .where('buyerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<String?> findBuyerUidByLineId(String lineId) async {
    final snap = await _firestore
        .collection('users')
        .where('lineId', isEqualTo: lineId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<Map<String, dynamic>?> getSellerRating(String sellerId) async {
    final doc = await _firestore.collection('users').doc(sellerId).get();
    if (!doc.exists) return null;
    return {
      'rating': (doc.data()?['rating'] as num?)?.toDouble(),
      'totalReviews': doc.data()?['totalReviews'] as int?,
    };
  }

  Future<void> createPendingRating({
    required String buyerUid,
    required String sellerId,
    required String sellerName,
    required String listingId,
    required String listingTitle,
  }) async {
    await _firestore.collection('pendingRatings').doc(listingId).set({
      'buyerUid': buyerUid,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitRating({
    required String pendingRatingId,
    required int rating,
  }) async {
    final pendingRef = _firestore.collection('pendingRatings').doc(pendingRatingId);
    final pendingSnap = await pendingRef.get();
    if (!pendingSnap.exists) return;
    final pendingData = pendingSnap.data()!;
    final sellerId = pendingData['sellerId'] as String? ?? '';
    final listingTitle = pendingData['listingTitle'] as String? ?? '';

    await _firestore.runTransaction((tx) async {
      final pendingDoc = await tx.get(pendingRef);
      if (!pendingDoc.exists) return;

      final data = pendingDoc.data()!;
      final sid = data['sellerId'] as String;
      final sellerRef = _firestore.collection('users').doc(sid);
      final sellerDoc = await tx.get(sellerRef);

      if (!sellerDoc.exists) {
        tx.delete(pendingRef);
        return;
      }

      final sellerData = sellerDoc.data()!;
      final oldRating = (sellerData['rating'] as num?)?.toDouble() ?? 0.0;
      final totalReviews = (sellerData['totalReviews'] as num?)?.toInt() ?? 0;
      final newRating = totalReviews == 0
          ? rating.toDouble()
          : (oldRating * totalReviews + rating) / (totalReviews + 1);

      tx.update(sellerRef, {
        'rating': newRating,
        'totalReviews': totalReviews + 1,
        'updatedAt': Timestamp.now(),
      });
      tx.delete(pendingRef);
    });

    if (sellerId.isNotEmpty) {
      _notifDs
          .send(
            recipientUid: sellerId,
            type: NotificationType.ratingReceived,
            title: 'New Rating Received',
            body: 'You received $rating star${rating != 1 ? 's' : ''} for "$listingTitle"',
            data: {'stars': rating, 'listingTitle': listingTitle},
          )
          .catchError((_) {});
    }
  }

  Future<void> skipRating(String pendingRatingId) async {
    await _firestore.collection('pendingRatings').doc(pendingRatingId).delete();
  }
}
