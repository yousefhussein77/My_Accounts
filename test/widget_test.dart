import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money math stays predictable', () {
    const debts = 125000.0;
    const payments = 45000.0;
    expect(debts - payments, 80000.0);
  });
}
