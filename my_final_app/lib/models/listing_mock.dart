import 'package:flutter/material.dart';

/// Mock listing data — replace with real Backend data in Phase 1
class ListingMock {
  final String id;
  final String name;
  final String tag;        // e.g., "Books/Used"
  final int price;
  final String emoji;      // placeholder before real images
  final Color bgStart;     // gradient start
  final Color bgEnd;       // gradient end
  final String category;

  const ListingMock({
    required this.id,
    required this.name,
    required this.tag,
    required this.price,
    required this.emoji,
    required this.bgStart,
    required this.bgEnd,
    required this.category,
  });

  /// Mock data for Home page
  static const List<ListingMock> samples = [
    ListingMock(
      id: '1',
      name: 'Calculus 1 Textbook',
      tag: 'Books/Used',
      price: 150,
      emoji: '📕',
      bgStart: Color(0xFF1A1A1A),
      bgEnd: Color(0xFF2D2D2D),
      category: 'textbooks',
    ),
    ListingMock(
      id: '2',
      name: 'KMUTT Engineering Workshop',
      tag: 'Clothes/Used',
      price: 350,
      emoji: '👔',
      bgStart: Color(0xFF2C3E50),
      bgEnd: Color(0xFF4A6278),
      category: 'fashion',
    ),
    ListingMock(
      id: '3',
      name: 'Dorm Desk Lamp',
      tag: 'Dorm ACCS/Used',
      price: 50,
      emoji: '💡',
      bgStart: Color(0xFFEFE2C5),
      bgEnd: Color(0xFFD4C39A),
      category: 'dorm',
    ),
    ListingMock(
      id: '4',
      name: 'Used Bicycle KMUTT',
      tag: 'Car/Used',
      price: 500,
      emoji: '🚲',
      bgStart: Color(0xFF8B7355),
      bgEnd: Color(0xFFA89074),
      category: 'vehicles',
    ),
    ListingMock(
      id: '5',
      name: 'Second Hand Calculator',
      tag: 'Electronic/Used',
      price: 200,
      emoji: '🧮',
      bgStart: Color(0xFF2C2C2C),
      bgEnd: Color(0xFF4A4A4A),
      category: 'electronics',
    ),
    ListingMock(
      id: '6',
      name: 'Ipad GEN 11 KMUTT',
      tag: 'Electronic/Used',
      price: 8000,
      emoji: '📱',
      bgStart: Color(0xFFB8C7DB),
      bgEnd: Color(0xFF8B9BB0),
      category: 'electronics',
    ),
  ];
}

class SwapMock {
  final String id;
  final String want;
  final String offer;

  const SwapMock({
    required this.id,
    required this.want,
    required this.offer,
  });

  static const List<SwapMock> samples = [
    SwapMock(id: '1', want: 'Dorm Fridge', offer: 'Monitor + Cash'),
    SwapMock(id: '2', want: 'Calculus Book', offer: 'Physic Book'),
    SwapMock(id: '3', want: 'Mini Fan', offer: 'Lamp + ฿100'),
  ];
}
