import 'package:my_accounts/domain/repositories/debt_repository.dart';

class DeletePersonUseCase {
  DeletePersonUseCase(this._repository);

  final DebtRepository _repository;

  Future<void> execute({
    required String userId,
    required String personId,
  }) async {
    await _repository.deletePerson(userId, personId);
  }
}
