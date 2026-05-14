/// User profile data model
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? lineId;
  final String? studentId;
  final String? faculty;
  final String? photoURL;
  final double rating;
  final int totalReviews;
  final int totalTrades;
  final bool isProfileComplete;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.lineId,
    this.studentId,
    this.faculty,
    this.photoURL,
    required this.rating,
    required this.totalReviews,
    required this.totalTrades,
    required this.isProfileComplete,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      lineId: json['lineId'] as String?,
      studentId: json['studentId'] as String?,
      faculty: json['faculty'] as String?,
      photoURL: json['photoURL'] as String?,
      rating: (json['rating'] as num).toDouble(),
      totalReviews: json['totalReviews'] as int,
      totalTrades: json['totalTrades'] as int,
      isProfileComplete: json['isProfileComplete'] as bool,
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? lineId,
    String? studentId,
    String? faculty,
    String? photoURL,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      lineId: lineId ?? this.lineId,
      studentId: studentId ?? this.studentId,
      faculty: faculty ?? this.faculty,
      photoURL: photoURL ?? this.photoURL,
      rating: rating,
      totalReviews: totalReviews,
      totalTrades: totalTrades,
      isProfileComplete: isProfileComplete,
    );
  }

  /// ⭐ Merge updates from Firestore document snapshot.
  /// Backend writes to users/{uid} directly when:
  ///  - Deal completed → totalTrades incremented
  ///  - Rating submitted → rating + totalReviews recalculated
  ///  - Profile edited → displayName / lineId / studentId / faculty changed
  ///
  /// This keeps the UI in sync without needing to call the API again.
  UserProfile mergeFromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: (data['email'] as String?) ?? email,
      displayName: (data['displayName'] as String?) ?? displayName,
      lineId: (data['lineId'] as String?) ?? lineId,
      studentId: (data['studentId'] as String?) ?? studentId,
      faculty: (data['faculty'] as String?) ?? faculty,
      photoURL: (data['photoURL'] as String?) ?? photoURL,
      rating: ((data['rating'] as num?) ?? rating).toDouble(),
      totalReviews: (data['totalReviews'] as int?) ?? totalReviews,
      totalTrades: (data['totalTrades'] as int?) ?? totalTrades,
      isProfileComplete: isProfileComplete,
    );
  }

  /// Used so we can detect "did anything actually change?" before notifying.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.lineId == lineId &&
        other.studentId == studentId &&
        other.faculty == faculty &&
        other.photoURL == photoURL &&
        other.rating == rating &&
        other.totalReviews == totalReviews &&
        other.totalTrades == totalTrades &&
        other.isProfileComplete == isProfileComplete;
  }

  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        lineId,
        studentId,
        faculty,
        photoURL,
        rating,
        totalReviews,
        totalTrades,
        isProfileComplete,
      );
}
