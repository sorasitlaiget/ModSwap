import '../../entities/listing.dart';
import '../../repositories/listing_repository.dart';

class CreateListingUseCase {
  final ListingRepository _repo;
  const CreateListingUseCase(this._repo);

  Future<Listing> call({
    required String title,
    String? description,
    ListingCategory? category,
    ListingType? type,
    num? price,
    String? swapPreference,
    ListingCondition? condition,
    List<String>? images,
    MeetingPoint? meetingPoint,
  }) => _repo.create(
    title: title,
    description: description,
    category: category,
    type: type,
    price: price,
    swapPreference: swapPreference,
    condition: condition,
    images: images,
    meetingPoint: meetingPoint,
  );
}
