import 'package:my_accounts/domain/repositories/debt_repository.dart';

class DeleteTransactionUseCase {
  DeleteTransactionUseCase(this._repository);

  final DebtRepository _repository;

  Future<void> execute({
    required String userId,
    required String transactionId,
  }) async {
    await _repository.deleteTransaction(userId, transactionId);
  }
}
