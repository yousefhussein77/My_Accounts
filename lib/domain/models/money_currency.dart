enum MoneyCurrency {
  yer('yer', 'ريال يمني', 'ر.ي'),
  sar('sar', 'ريال سعودي', 'ر.س'),
  usd('usd', 'دولار', r'$');

  const MoneyCurrency(this.code, this.label, this.symbol);

  final String code;
  final String label;
  final String symbol;

  static MoneyCurrency fromCode(String? code) {
    return MoneyCurrency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => MoneyCurrency.yer,
    );
  }
}
