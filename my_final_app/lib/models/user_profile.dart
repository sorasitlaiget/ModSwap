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
}
