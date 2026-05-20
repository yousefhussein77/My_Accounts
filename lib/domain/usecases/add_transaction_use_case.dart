import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:my_accounts/domain/repositories/debt_repository.dart';
import 'package:uuid/uuid.dart';

class AddTransactionInput {
  const AddTransactionInput({
    required this.userId,
    required this.personId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.title,
    this.note = '',
    this.dueDate,
  });

  final String userId;
  final String personId;
  final DebtTransactionType type;
  final double amount;
  final MoneyCurrency currency;
  final String title;
  final String note;
  final DateTime? dueDate;
}

class AddTransactionUseCase {
  AddTransactionUseCase(this._repository);

  final DebtRepository _repository;
  final Uuid _uuid = const Uuid();

  Future<void> execute(AddTransactionInput input) async {
    final personAllowed = await _repository.personBelongsToUser(
      input.userId,
      input.personId,
    );
    if (!personAllowed) {
      throw Exception('لا يمكن تسجيل عملية لشخص غير تابع لحسابك');
    }

    await _repository.saveTransaction(
      input.userId,
      DebtTransaction(
        id: _uuid.v4(),
        personId: input.personId,
        type: input.type,
        amount: input.amount,
        currency: input.currency,
        title: input.title,
        note: input.note,
        date: DateTime.now(),
        dueDate: input.dueDate,
      ),
    );
  }
}
