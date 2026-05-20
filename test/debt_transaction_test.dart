import 'package:flutter_test/flutter_test.dart';
import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:my_accounts/domain/models/money_currency.dart';

void main() {
  DebtTransaction tx({
    required DebtTransactionType type,
    DateTime? dueDate,
  }) {
    return DebtTransaction(
      id: 'tx-1',
      personId: 'person-1',
      type: type,
      amount: 100,
      currency: MoneyCurrency.yer,
      title: type == DebtTransactionType.debt ? 'عليك' : 'لك',
      note: '',
      date: DateTime.now(),
      dueDate: dueDate,
    );
  }

  group('DebtTransaction.isOverdue', () {
    test('does not mark debts due today as overdue', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(
        tx(type: DebtTransactionType.debt, dueDate: today).isOverdue,
        isFalse,
      );
    });

    test('marks debts due before today as overdue', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(
        tx(type: DebtTransactionType.debt, dueDate: yesterday).isOverdue,
        isTrue,
      );
    });

    test('does not mark payments as overdue even with an old due date', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 30));

      expect(
        tx(type: DebtTransactionType.payment, dueDate: oldDate).isOverdue,
        isFalse,
      );
    });
  });
}
