sealed class Failure {
  final String message;
  const Failure(this.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ListingFailure extends Failure {
  const ListingFailure(super.message);
}

class WishlistFailure extends Failure {
  const WishlistFailure(super.message);
}

class NotificationFailure extends Failure {
  const NotificationFailure(super.message);
}

class RatingFailure extends Failure {
  const RatingFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
