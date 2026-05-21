import 'package:flutter_test/flutter_test.dart';
import 'package:my_accounts/domain/models/debt_person.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:my_accounts/domain/models/person_summary.dart';

void main() {
  final person = DebtPerson(
    id: 'person-1',
    name: 'محمد',
    phone: '',
    note: '',
    isFavorite: false,
    createdAt: DateTime(2026),
  );

  group('PersonSummary', () {
    test('keeps balances separated by currency direction', () {
      final summary = PersonSummary(
        person: person,
        balance: 0,
        debtTotal: 0,
        paymentTotal: 0,
        balanceByCurrency: const {
          MoneyCurrency.yer: 50000,
          MoneyCurrency.usd: -20,
        },
        lastActivity: null,
      );

      expect(summary.hasDebt, isTrue);
      expect(summary.hasCredit, isTrue);
      expect(summary.hasMixedDirection, isTrue);
      expect(summary.exposureScore, 50020);
      expect(summary.isSettled, isFalse);
      expect(summary.hasActivityIn(MoneyCurrency.yer), isTrue);
      expect(summary.hasActivityIn(MoneyCurrency.sar), isFalse);
      expect(summary.activeCurrencies, [
        MoneyCurrency.yer,
        MoneyCurrency.usd,
      ]);
    });

    test('calculates progress only for a single debt currency', () {
      final summary = PersonSummary(
        person: person,
        balance: 600,
        debtTotal: 1000,
        paymentTotal: 400,
        debtByCurrency: const {MoneyCurrency.yer: 1000},
        paymentByCurrency: const {MoneyCurrency.yer: 400},
        lastActivity: null,
      );

      expect(summary.singleCurrencyProgress, 0.4);
    });

    test('does not calculate progress when multiple debt currencies exist', () {
      final summary = PersonSummary(
        person: person,
        balance: 0,
        debtTotal: 0,
        paymentTotal: 0,
        debtByCurrency: const {
          MoneyCurrency.yer: 1000,
          MoneyCurrency.usd: 50,
        },
        paymentByCurrency: const {MoneyCurrency.yer: 400},
        lastActivity: null,
      );

      expect(summary.singleCurrencyProgress, isNull);
    });
  });
}
