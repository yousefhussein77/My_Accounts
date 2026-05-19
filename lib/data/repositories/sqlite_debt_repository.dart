import 'package:debt_ledger_app/data/local/app_database.dart';
import 'package:debt_ledger_app/domain/models/debt_person.dart';
import 'package:debt_ledger_app/domain/models/debt_transaction.dart';
import 'package:debt_ledger_app/domain/models/money_currency.dart';
import 'package:debt_ledger_app/domain/models/person_summary.dart';
import 'package:debt_ledger_app/domain/repositories/debt_repository.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class SqliteDebtRepository implements DebtRepository {
  SqliteDebtRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<PersonSummary>> people(String userId) async {
    final db = await _database.database;
    final personRows = await db.query(
      'people',
      where: 'owner_user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_favorite DESC, name ASC',
    );
    final txRows = await db.query(
      'debt_transactions',
      where: 'owner_user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    final txs = txRows.map(DebtTransaction.fromMap).toList();
    return personRows.map((row) {
      final person = DebtPerson.fromMap(row);
      final personTxs = txs.where((tx) => tx.personId == person.id).toList();
      final debtTotal = personTxs
          .where((tx) => tx.type == DebtTransactionType.debt)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final paymentTotal = personTxs
          .where((tx) => tx.type == DebtTransactionType.payment)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final debtByCurrency = _totalsByCurrency(
        personTxs.where((tx) => tx.type == DebtTransactionType.debt),
      );
      final paymentByCurrency = _totalsByCurrency(
        personTxs.where((tx) => tx.type == DebtTransactionType.payment),
      );
      return PersonSummary(
        person: person,
        balance: debtTotal - paymentTotal,
        debtTotal: debtTotal,
        paymentTotal: paymentTotal,
        balanceByCurrency: {
          for (final currency in MoneyCurrency.values)
            currency: (debtByCurrency[currency] ?? 0) -
                (paymentByCurrency[currency] ?? 0),
        },
        debtByCurrency: debtByCurrency,
        paymentByCurrency: paymentByCurrency,
        lastActivity: personTxs.isEmpty ? null : personTxs.first.date,
      );
    }).toList();
  }

  @override
  Future<DebtPerson?> person(String userId, String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'people',
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DebtPerson.fromMap(rows.first);
  }

  @override
  Future<void> savePerson(String userId, DebtPerson person) async {
    final db = await _database.database;
    await db.insert(
      'people',
      {
        ...person.toMap(),
        'owner_user_id': userId,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deletePerson(String userId, String id) async {
    final db = await _database.database;
    await db.delete(
      'people',
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, userId],
    );
  }

  @override
  Future<List<DebtTransaction>> transactions(String userId, {String? personId}) async {
    final db = await _database.database;
    final where = personId == null
        ? 'owner_user_id = ?'
        : 'owner_user_id = ? AND person_id = ?';
    final whereArgs = personId == null
        ? <Object?>[userId]
        : <Object?>[userId, personId];
    final rows = await db.query(
      'debt_transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return rows.map(DebtTransaction.fromMap).toList();
  }

  @override
  Future<void> saveTransaction(String userId, DebtTransaction transaction) async {
    final db = await _database.database;
    await db.insert(
      'debt_transactions',
      {
        ...transaction.toMap(),
        'owner_user_id': userId,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTransaction(String userId, String id) async {
    final db = await _database.database;
    await db.delete(
      'debt_transactions',
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Map<MoneyCurrency, double> _totalsByCurrency(Iterable<DebtTransaction> txs) {
    final totals = <MoneyCurrency, double>{};
    for (final tx in txs) {
      totals[tx.currency] = (totals[tx.currency] ?? 0) + tx.amount;
    }
    return totals;
  }
}
