import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/listing_remote_datasource.dart';
import '../../data/datasources/remote/notification_remote_datasource.dart';
import '../../data/datasources/remote/rating_remote_datasource.dart';
import '../../data/network/dio_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/listing_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/rating_repository_impl.dart';
import '../../data/repositories/wishlist_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/rating_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../domain/usecases/auth/complete_profile_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/update_profile_usecase.dart';
import '../../domain/usecases/listing/create_listing_usecase.dart';
import '../../domain/usecases/listing/get_listing_by_id_usecase.dart';
import '../../domain/usecases/listing/get_listings_usecase.dart';
import '../../domain/usecases/notification/mark_all_read_usecase.dart';
import '../../domain/usecases/notification/mark_read_usecase.dart';
import '../../domain/usecases/notification/watch_notifications_usecase.dart';
import '../../domain/usecases/wishlist/get_wishlist_usecase.dart';
import '../../domain/usecases/wishlist/toggle_wishlist_usecase.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final _firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(ref.read(_firebaseAuthProvider)),
);

// ─── Data Sources ─────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(
    ref.read(_firebaseAuthProvider),
    ref.read(dioClientProvider),
  ),
);

final listingRemoteDataSourceProvider = Provider<ListingRemoteDataSource>(
  (ref) => ListingRemoteDataSource(ref.read(dioClientProvider)),
);

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>(
  (ref) => NotificationRemoteDataSource(ref.read(_firestoreProvider)),
);

final ratingRemoteDataSourceProvider = Provider<RatingRemoteDataSource>(
  (ref) => RatingRemoteDataSource(
    ref.read(_firestoreProvider),
    ref.read(notificationRemoteDataSourceProvider),
  ),
);

// ─── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
    ref.read(_firestoreProvider),
  ),
);

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepositoryImpl(ref.read(listingRemoteDataSourceProvider)),
);

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepositoryImpl(ref.read(listingRemoteDataSourceProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    ref.read(notificationRemoteDataSourceProvider),
  ),
);

final ratingRepositoryProvider = Provider<RatingRepository>(
  (ref) => RatingRepositoryImpl(ref.read(ratingRemoteDataSourceProvider)),
);

// ─── Use Cases — Auth ─────────────────────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.read(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);

final completeProfileUseCaseProvider = Provider<CompleteProfileUseCase>(
  (ref) => CompleteProfileUseCase(ref.read(authRepositoryProvider)),
);

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(ref.read(authRepositoryProvider)),
);

// ─── Use Cases — Listing ──────────────────────────────────────────────────────

final getListingsUseCaseProvider = Provider<GetListingsUseCase>(
  (ref) => GetListingsUseCase(ref.read(listingRepositoryProvider)),
);

final getListingByIdUseCaseProvider = Provider<GetListingByIdUseCase>(
  (ref) => GetListingByIdUseCase(ref.read(listingRepositoryProvider)),
);

final createListingUseCaseProvider = Provider<CreateListingUseCase>(
  (ref) => CreateListingUseCase(ref.read(listingRepositoryProvider)),
);

// ─── Use Cases — Wishlist ─────────────────────────────────────────────────────

final getWishlistUseCaseProvider = Provider<GetWishlistUseCase>(
  (ref) => GetWishlistUseCase(ref.read(wishlistRepositoryProvider)),
);

final toggleWishlistUseCaseProvider = Provider<ToggleWishlistUseCase>(
  (ref) => ToggleWishlistUseCase(ref.read(wishlistRepositoryProvider)),
);

// ─── Use Cases — Notification ─────────────────────────────────────────────────

final watchNotificationsUseCaseProvider = Provider<WatchNotificationsUseCase>(
  (ref) => WatchNotificationsUseCase(ref.read(notificationRepositoryProvider)),
);

final markReadUseCaseProvider = Provider<MarkReadUseCase>(
  (ref) => MarkReadUseCase(ref.read(notificationRepositoryProvider)),
);

final markAllReadUseCaseProvider = Provider<MarkAllReadUseCase>(
  (ref) => MarkAllReadUseCase(ref.read(notificationRepositoryProvider)),
);
