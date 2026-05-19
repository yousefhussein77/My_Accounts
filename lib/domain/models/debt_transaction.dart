import 'package:debt_ledger_app/domain/models/money_currency.dart';

enum DebtTransactionType { debt, payment }

class DebtTransaction {
  const DebtTransaction({
    required this.id,
    required this.personId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.title,
    required this.note,
    required this.date,
    this.dueDate,
  });

  final String id;
  final String personId;
  final DebtTransactionType type;
  final double amount;
  final MoneyCurrency currency;
  final String title;
  final String note;
  final DateTime date;
  final DateTime? dueDate;

  bool get isOverdue =>
      type == DebtTransactionType.debt &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  Map<String, Object?> toMap() => {
        'id': id,
        'person_id': personId,
        'type': type.name,
        'amount': amount,
        'currency': currency.code,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
      };

  factory DebtTransaction.fromMap(Map<String, Object?> map) => DebtTransaction(
        id: map['id'] as String,
        personId: map['person_id'] as String,
        type: DebtTransactionType.values.byName(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        currency: MoneyCurrency.fromCode(map['currency'] as String?),
        title: map['title'] as String,
        note: map['note'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        dueDate: map['due_date'] == null
            ? null
            : DateTime.parse(map['due_date'] as String),
      );
}
