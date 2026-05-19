/// Listing data model — matches Backend `ListingResponseDto`
library;

// ============================================================
// Enums
// ============================================================

enum ListingCategory {
  textbooks('textbooks', 'Textbooks'),
  electronics('electronics', 'Electronics'),
  fashion('fashion', 'Fashion'),
  dorm('dorm', 'Housing/Dorm'),
  vehicles('vehicles', 'Vehicles'),
  others('others', 'Others');

  final String apiValue;
  final String displayName;
  const ListingCategory(this.apiValue, this.displayName);

  static ListingCategory? fromApi(String? value) {
    if (value == null) return null;
    for (final c in ListingCategory.values) {
      if (c.apiValue == value) return c;
    }
    return null;
  }
}

enum ListingType {
  sell('sell', 'Sell'),
  trade('trade', 'Trade'),
  both('both', 'Sell + Trade');

  final String apiValue;
  final String displayName;
  const ListingType(this.apiValue, this.displayName);

  static ListingType? fromApi(String? value) {
    if (value == null) return null;
    for (final t in ListingType.values) {
      if (t.apiValue == value) return t;
    }
    return null;
  }
}

enum ListingCondition {
  newItem('new', 'NEW'),
  likeNew('like-new', 'LIKENEW'),
  used('used', 'USED');

  final String apiValue;
  final String displayName;
  const ListingCondition(this.apiValue, this.displayName);

  static ListingCondition? fromApi(String? value) {
    if (value == null) return null;
    for (final c in ListingCondition.values) {
      if (c.apiValue == value) return c;
    }
    return null;
  }
}

enum ListingState {
  draft('draft', 'Draft'),
  published('published', 'Published'),
  sold('sold', 'Sold'),
  removed('removed', 'Removed');

  final String apiValue;
  final String displayName;
  const ListingState(this.apiValue, this.displayName);

  static ListingState fromApi(String value) {
    for (final s in ListingState.values) {
      if (s.apiValue == value) return s;
    }
    return ListingState.draft;
  }
}

// ============================================================
// Meeting Point
// ============================================================

class MeetingPoint {
  final String name;
  final double latitude;
  final double longitude;
  final String? placeId;

  const MeetingPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  factory MeetingPoint.fromJson(Map<String, dynamic> json) {
    return MeetingPoint(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeId: json['placeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'placeId': placeId,
  };

  @override
  bool operator ==(Object other) =>
      other is MeetingPoint &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(name, latitude, longitude);
}

// ============================================================
// Listing
// ============================================================

class Listing {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerStudentId;
  final String ownerLineId;

  final String title;
  final String? description;
  final ListingCategory? category;
  final ListingType? type;

  final num? price;
  final String? swapPreference;

  final List<String> images;
  final String? thumbnailURL;

  final ListingCondition? condition;
  final MeetingPoint? meetingPoint;

  final ListingState state;
  final int views;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const Listing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerStudentId,
    required this.ownerLineId,
    required this.title,
    this.description,
    this.category,
    this.type,
    this.price,
    this.swapPreference,
    required this.images,
    this.thumbnailURL,
    this.condition,
    this.meetingPoint,
    required this.state,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      ownerStudentId: json['ownerStudentId'] as String,
      ownerLineId: json['ownerLineId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: ListingCategory.fromApi(json['category'] as String?),
      type: ListingType.fromApi(json['type'] as String?),
      price: json['price'] as num?,
      swapPreference: json['swapPreference'] as String?,
      images: (json['images'] as List<dynamic>).cast<String>(),
      thumbnailURL: json['thumbnailURL'] as String?,
      condition: ListingCondition.fromApi(json['condition'] as String?),
      meetingPoint: json['meetingPoint'] != null
          ? MeetingPoint.fromJson(json['meetingPoint'] as Map<String, dynamic>)
          : null,
      state: ListingState.fromApi(json['state'] as String),
      views: json['views'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
    );
  }

  /// Helper: format price as "฿1,500"
  String get formattedPrice {
    if (price == null) return '';
    return '฿${price!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String get stateLabel => state.displayName;

  bool get isDraft => state == ListingState.draft;
  bool get isPublished => state == ListingState.published;
  bool get isSold => state == ListingState.sold;
}

// ============================================================
// KMUTT Pre-defined Meeting Points
// ============================================================

class KmuttPlaces {
  static const List<MeetingPoint> all = [
    MeetingPoint(
      name: 'ลานเกียร์ (KMUTT Bangmod)',
      latitude: 13.6517,
      longitude: 100.4948,
    ),
    MeetingPoint(
      name: 'อาคารเรียนรวม 4 (CB4)',
      latitude: 13.6505,
      longitude: 100.4946,
    ),
    MeetingPoint(
      name: 'อาคารวิศววัฒนะ (S1)',
      latitude: 13.6510,
      longitude: 100.4950,
    ),
    MeetingPoint(name: 'หอสมุด KMUTT', latitude: 13.6516, longitude: 100.4955),
    MeetingPoint(name: 'โรงอาหารกลาง', latitude: 13.6512, longitude: 100.4944),
    MeetingPoint(
      name: 'อาคารเรียนรวม 2 (CB2)',
      latitude: 13.6509,
      longitude: 100.4942,
    ),
    MeetingPoint(
      name: 'หอพักนักศึกษา (Dorm)',
      latitude: 13.6485,
      longitude: 100.4955,
    ),
    MeetingPoint(
      name: 'ป้ายรถเมล์ มจธ.',
      latitude: 13.6498,
      longitude: 100.4940,
    ),
    MeetingPoint(
      name: 'อาคารพระจอมเกล้าราชานุสรณ์ 190 ปี',
      latitude: 13.6520,
      longitude: 100.4953,
    ),
    MeetingPoint(
      name: 'สนามฟุตบอล KMUTT',
      latitude: 13.6504,
      longitude: 100.4960,
    ),
  ];
}

// ============================================================
// Search Result (Listing + similarity score from semantic search)
// ============================================================

/// Wraps a Listing with its similarity score from semantic search.
/// Returned by `POST /listings/search` endpoint.
class SearchResult {
  final Listing listing;

  /// Cosine similarity score (0.0 - 1.0)
  /// Higher means more semantically similar to the search query.
  final double score;

  SearchResult({required this.listing, required this.score});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      // Backend returns listing fields + score in the same object,
      // so we can use the listing's fromJson directly.
      listing: Listing.fromJson(json),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Relevance percentage (for UI display)
  /// 0.75 → "75% match"
  int get matchPercent => (score * 100).round();
}
