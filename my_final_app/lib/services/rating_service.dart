import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class RatingService {
  final _notifService = NotificationService();
  final _firestore = FirebaseFirestore.instance;

  // ─── Real-time listener ─────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingRatingsStream(String uid) {
    return _firestore
        .collection('pendingRatings')
        .where('buyerUid', isEqualTo: uid)
        .snapshots();
  }

  // ─── Lookup ─────────────────────────────────────────────────────────────

  /// Find buyer's UID by their LINE ID (stored on user profile)
  Future<String?> findBuyerUidByLineId(String lineId) async {
    final snap = await _firestore
        .collection('users')
        .where('lineId', isEqualTo: lineId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  // ─── Write ──────────────────────────────────────────────────────────────

  Future<void> createPendingRating({
    required String buyerUid,
    required String sellerId,
    required String sellerName,
    required String listingId,
    required String listingTitle,
  }) async {
    // Use listingId as document ID — prevents duplicate pending ratings
    // for the same listing (idempotent upsert).
    await _firestore.collection('pendingRatings').doc(listingId).set({
      'buyerUid': buyerUid,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Submit rating — updates seller's weighted average and deletes pending doc
  Future<void> submitRating({
    required String pendingRatingId,
    required int rating,
  }) async {
    final pendingRef = _firestore
        .collection('pendingRatings')
        .doc(pendingRatingId);

    // Read outside transaction to capture recipient info for notification
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

    // Fire-and-forget: notify seller they received a rating
    if (sellerId.isNotEmpty) {
      _notifService
          .send(
            recipientUid: sellerId,
            type: NotificationType.ratingReceived,
            title: 'New Rating Received',
            body:
                'You received $rating star${rating != 1 ? 's' : ''} for "$listingTitle"',
            data: {'stars': rating, 'listingTitle': listingTitle},
          )
          .catchError((_) {});
    }
  }

  /// Skip — just deletes the pending rating without submitting a score
  Future<void> skipRating(String pendingRatingId) async {
    await _firestore.collection('pendingRatings').doc(pendingRatingId).delete();
  }
}
