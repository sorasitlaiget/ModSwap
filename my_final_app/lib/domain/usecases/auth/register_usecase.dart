import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repo;
  const RegisterUseCase(this._repo);
  Future<void> call(String email, String password) =>
      _repo.register(email, password);
}
