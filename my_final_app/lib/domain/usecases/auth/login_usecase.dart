import '../../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;
  const LoginUseCase(this._repo);
  Future<void> call(String email, String password) =>
      _repo.login(email, password);
}
