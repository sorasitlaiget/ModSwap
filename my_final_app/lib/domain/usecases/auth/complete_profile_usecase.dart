import '../../entities/user_profile.dart';
import '../../repositories/auth_repository.dart';

class CompleteProfileUseCase {
  final AuthRepository _repo;
  const CompleteProfileUseCase(this._repo);

  Future<UserProfile> call({
    required String displayName,
    required String studentId,
    required String faculty,
    required String lineId,
  }) => _repo.completeProfile(
    displayName: displayName,
    studentId: studentId,
    faculty: faculty,
    lineId: lineId,
  );
}
