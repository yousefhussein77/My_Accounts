import 'package:my_accounts/domain/models/debt_person.dart';
import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:my_accounts/domain/models/person_summary.dart';

abstract class DebtRepository {
  Future<List<PersonSummary>> people(String userId);
  Future<DebtPerson?> person(String userId, String id);
  Future<void> savePerson(String userId, DebtPerson person);
  Future<void> deletePerson(String userId, String id);
  Future<List<DebtTransaction>> transactions(String userId, {String? personId});
  Future<bool> personBelongsToUser(String userId, String personId);
  Future<void> saveTransaction(String userId, DebtTransaction transaction);
  Future<void> deleteTransaction(String userId, String id);
}
