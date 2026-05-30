import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/models/listing.dart';

void main() {
  group('ListingCategory.fromApi', () {
    test('parses valid api values', () {
      expect(ListingCategory.fromApi('textbooks'), ListingCategory.textbooks);
      expect(ListingCategory.fromApi('electronics'), ListingCategory.electronics);
      expect(ListingCategory.fromApi('fashion'), ListingCategory.fashion);
      expect(ListingCategory.fromApi('dorm'), ListingCategory.dorm);
      expect(ListingCategory.fromApi('vehicles'), ListingCategory.vehicles);
      expect(ListingCategory.fromApi('others'), ListingCategory.others);
    });

    test('returns null for unknown value', () {
      expect(ListingCategory.fromApi('unknown'), isNull);
    });

    test('returns null for null input', () {
      expect(ListingCategory.fromApi(null), isNull);
    });
  });

  group('ListingType.fromApi', () {
    test('parses all valid api values', () {
      expect(ListingType.fromApi('sell'), ListingType.sell);
      expect(ListingType.fromApi('trade'), ListingType.trade);
      expect(ListingType.fromApi('both'), ListingType.both);
    });

    test('returns null for unknown value', () {
      expect(ListingType.fromApi('auction'), isNull);
    });
  });

  group('ListingCondition.fromApi', () {
    test('parses all valid api values', () {
      expect(ListingCondition.fromApi('new'), ListingCondition.newItem);
      expect(ListingCondition.fromApi('like-new'), ListingCondition.likeNew);
      expect(ListingCondition.fromApi('used'), ListingCondition.used);
    });

    test('returns null for unknown value', () {
      expect(ListingCondition.fromApi('broken'), isNull);
    });
  });

  group('ListingCategory display names', () {
    test('all categories have non-empty display names', () {
      for (final cat in ListingCategory.values) {
        expect(cat.displayName, isNotEmpty);
      }
    });
  });

  group('ListingType display names', () {
    test('all types have non-empty display names', () {
      for (final type in ListingType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });
  });

  group('ListingCondition display names', () {
    test('all conditions have non-empty display names', () {
      for (final cond in ListingCondition.values) {
        expect(cond.displayName, isNotEmpty);
      }
    });
  });
}
