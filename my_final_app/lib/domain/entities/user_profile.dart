// Domain entity — pure Dart, zero Flutter/Firebase imports

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

  // Merges Firestore real-time updates (backend writes rating/trades directly).
  // Takes plain Map<String, dynamic> — no Firebase import needed.
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
    id, email, displayName, lineId, studentId,
    faculty, photoURL, rating, totalReviews, totalTrades, isProfileComplete,
  );
}
