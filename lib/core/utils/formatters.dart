import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static final _date = DateFormat.yMMMd('ar');
  static final _month = DateFormat.yMMMM('ar');

  static String money(num value, [MoneyCurrency currency = MoneyCurrency.yer]) {
    return NumberFormat.currency(
      locale: 'ar',
      symbol: currency.symbol,
      decimalDigits: 0,
    ).format(value);
  }

  static String amount(num value) {
    return NumberFormat.decimalPattern('ar').format(value);
  }

  static String date(DateTime value) => _date.format(value);
  static String month(DateTime value) => _month.format(value);
}
