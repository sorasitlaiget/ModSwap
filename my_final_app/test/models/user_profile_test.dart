import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/domain/entities/user_profile.dart';

void main() {
  const baseProfile = UserProfile(
    id: 'uid123',
    email: 'student@mail.kmutt.ac.th',
    displayName: 'Test User',
    studentId: '63130500001',
    faculty: 'Engineering',
    lineId: 'testline',
    rating: 4.5,
    totalReviews: 10,
    totalTrades: 5,
    isProfileComplete: true,
  );

  group('UserProfile.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'uid123',
        'email': 'student@mail.kmutt.ac.th',
        'displayName': 'Test User',
        'studentId': '63130500001',
        'faculty': 'Engineering',
        'lineId': 'testline',
        'photoURL': null,
        'rating': 4.5,
        'totalReviews': 10,
        'totalTrades': 5,
        'isProfileComplete': true,
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.id, 'uid123');
      expect(profile.email, 'student@mail.kmutt.ac.th');
      expect(profile.rating, 4.5);
      expect(profile.isProfileComplete, true);
    });

    test('parses rating from int', () {
      final json = {
        'id': 'u1',
        'email': 'a@mail.kmutt.ac.th',
        'displayName': 'A',
        'photoURL': null,
        'lineId': null,
        'studentId': null,
        'faculty': null,
        'rating': 5,
        'totalReviews': 0,
        'totalTrades': 0,
        'isProfileComplete': false,
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.rating, 5.0);
      expect(profile.rating, isA<double>());
    });
  });

  group('UserProfile.copyWith', () {
    test('updates only specified fields', () {
      final updated = baseProfile.copyWith(displayName: 'New Name');
      expect(updated.displayName, 'New Name');
      expect(updated.id, baseProfile.id);
      expect(updated.email, baseProfile.email);
      expect(updated.rating, baseProfile.rating);
    });

    test('returns same values when no args given', () {
      final copy = baseProfile.copyWith();
      expect(copy.displayName, baseProfile.displayName);
      expect(copy.studentId, baseProfile.studentId);
    });
  });

  group('UserProfile.mergeFromFirestore', () {
    test('merges updated rating and trades', () {
      final merged = baseProfile.mergeFromFirestore({
        'rating': 4.8,
        'totalReviews': 12,
        'totalTrades': 7,
      });
      expect(merged.rating, 4.8);
      expect(merged.totalReviews, 12);
      expect(merged.totalTrades, 7);
      expect(merged.id, baseProfile.id);
    });

    test('keeps original values for missing fields', () {
      final merged = baseProfile.mergeFromFirestore({});
      expect(merged.rating, baseProfile.rating);
      expect(merged.displayName, baseProfile.displayName);
    });
  });

  group('UserProfile equality', () {
    test('equal profiles return true', () {
      const copy = UserProfile(
        id: 'uid123',
        email: 'student@mail.kmutt.ac.th',
        displayName: 'Test User',
        studentId: '63130500001',
        faculty: 'Engineering',
        lineId: 'testline',
        rating: 4.5,
        totalReviews: 10,
        totalTrades: 5,
        isProfileComplete: true,
      );
      expect(baseProfile, equals(copy));
    });

    test('different profiles return false', () {
      final different = baseProfile.copyWith(displayName: 'Other');
      expect(baseProfile, isNot(equals(different)));
    });
  });
}
