import 'package:my_accounts/core/utils/formatters.dart';
import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:my_accounts/presentation/shared/app_header.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:my_accounts/presentation/shared/currency_totals_view.dart';
import 'package:my_accounts/presentation/shared/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (data) {
            final now = DateTime.now();
            final monthTxs = data.transactions
                .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
                .toList();

            final debtTotals = _totalsByCurrency(
              monthTxs.where((tx) => tx.type == DebtTransactionType.debt),
            );
            final paidTotals = _totalsByCurrency(
              monthTxs.where((tx) => tx.type == DebtTransactionType.payment),
            );

            final activeCurrencies = MoneyCurrency.values.where((currency) {
              final debt = debtTotals[currency] ?? 0;
              final paid = paidTotals[currency] ?? 0;
              return debt > 0 || paid > 0;
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                AppHeader(title: 'التقارير', subtitle: 'ملخص ${AppFormatters.month(now)}'),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                  children: [
                    MetricCard(
                      title: 'إجمالي عليك',
                      valueChild: CurrencyTotalsView(
                        totals: debtTotals,
                        color: colors.error,
                        compact: true,
                      ),
                      icon: LucideIcons.arrowUpRight,
                      color: colors.error,
                    ),
                    MetricCard(
                      title: 'إجمالي لك',
                      valueChild: CurrencyTotalsView(
                        totals: paidTotals,
                        color: colors.primary,
                        compact: true,
                      ),
                      icon: LucideIcons.arrowDownLeft,
                      color: colors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'مؤشر هذا الشهر',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (activeCurrencies.isEmpty)
                  const Text('لا توجد عمليات هذا الشهر')
                else
                  ...activeCurrencies.map((currency) {
                    final debt = debtTotals[currency] ?? 0;
                    final paid = paidTotals[currency] ?? 0;
                    final maxValue = [debt, paid, 1.0].reduce((a, b) => a > b ? a : b);
                    return Column(
                      children: [
                        _ReportBar(
                          label: 'عليك (${currency.label})',
                          value: debt,
                          valueLabel: AppFormatters.money(debt, currency),
                          max: maxValue,
                          color: colors.error,
                        ),
                        _ReportBar(
                          label: 'لك (${currency.label})',
                          value: paid,
                          valueLabel: AppFormatters.money(paid, currency),
                          max: maxValue,
                          color: colors.primary,
                        ),
                      ],
                    );
                  }),
                const SizedBox(height: 22),
                Text(
                  'أعلى المتابعات',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...data.people.take(5).map(
                  (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.userCheck),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.person.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CurrencyTotalsView(
                            totals: item.balanceByCurrency,
                            compact: true,
                            showDirection: true,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CurrencyTotalsView(
                                totals: item.debtByCurrency,
                                color: colors.error,
                                compact: true,
                              ),
                              CurrencyTotalsView(
                                totals: item.paymentByCurrency,
                                color: colors.primary,
                                compact: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportBar extends StatelessWidget {
  const _ReportBar({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.max,
    required this.color,
  });

  final String label;
  final double value;
  final String valueLabel;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(valueLabel),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value / max,
            minHeight: 12,
            borderRadius: BorderRadius.circular(8),
            color: color,
          ),
        ],
      ),
    );
  }
}

Map<MoneyCurrency, double> _totalsByCurrency(Iterable<DebtTransaction> txs) {
  final totals = <MoneyCurrency, double>{};
  for (final tx in txs) {
    totals[tx.currency] = (totals[tx.currency] ?? 0) + tx.amount;
  }
  return totals;
}
