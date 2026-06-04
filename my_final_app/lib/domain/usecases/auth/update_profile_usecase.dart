import '../../entities/user_profile.dart';
import '../../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repo;
  const UpdateProfileUseCase(this._repo);

  Future<UserProfile> call({
    String? displayName,
    String? studentId,
    String? faculty,
    String? lineId,
  }) => _repo.updateProfile(
    displayName: displayName,
    studentId: studentId,
    faculty: faculty,
    lineId: lineId,
  );
}
