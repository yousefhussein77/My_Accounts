import 'package:my_accounts/domain/models/debt_person.dart';
import 'package:my_accounts/domain/models/money_currency.dart';

class PersonSummary {
  const PersonSummary({
    required this.person,
    required this.balance,
    required this.debtTotal,
    required this.paymentTotal,
    this.balanceByCurrency = const {},
    this.debtByCurrency = const {},
    this.paymentByCurrency = const {},
    required this.lastActivity,
  });

  final DebtPerson person;
  final double balance;
  final double debtTotal;
  final double paymentTotal;
  final Map<MoneyCurrency, double> balanceByCurrency;
  final Map<MoneyCurrency, double> debtByCurrency;
  final Map<MoneyCurrency, double> paymentByCurrency;
  final DateTime? lastActivity;

  bool get isSettled =>
      balanceByCurrency.values.every((value) => value == 0);

  bool get hasDebt =>
      balanceByCurrency.values.any((value) => value > 0);

  bool get hasCredit =>
      balanceByCurrency.values.any((value) => value < 0);

  bool get hasMixedDirection => hasDebt && hasCredit;

  List<MoneyCurrency> get activeCurrencies {
    return MoneyCurrency.values
        .where((currency) => hasActivityIn(currency))
        .toList();
  }

  bool hasActivityIn(MoneyCurrency currency) {
    return (balanceByCurrency[currency] ?? 0) != 0 ||
        (debtByCurrency[currency] ?? 0) != 0 ||
        (paymentByCurrency[currency] ?? 0) != 0;
  }

  // Used for sorting by financial weight without mixing signed totals.
  double get exposureScore => balanceByCurrency.values.fold(
        0.0,
        (sum, value) => sum + value.abs(),
      );

  // Progress can be shown only when all debt exists in a single currency.
  double? get singleCurrencyProgress {
    final activeDebt = debtByCurrency.entries.where((e) => e.value > 0).toList();
    if (activeDebt.length != 1) return null;
    final currency = activeDebt.first.key;
    final debt = activeDebt.first.value;
    if (debt <= 0) return null;
    final paid = paymentByCurrency[currency] ?? 0;
    return (paid / debt).clamp(0.0, 1.0);
  }
}
