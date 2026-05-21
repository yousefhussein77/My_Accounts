import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/core/utils/formatters.dart';
import 'package:my_accounts/core/widgets/confirm_dialog.dart';
import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:my_accounts/domain/models/person_summary.dart';
import 'package:my_accounts/presentation/people/person_form_sheet.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:my_accounts/presentation/shared/currency_totals_view.dart';
import 'package:my_accounts/presentation/transactions/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({required this.personId, super.key});

  final String personId;

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  MoneyCurrency? _selectedCurrency;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtControllerProvider);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => showTransactionFormSheet(
              context,
              personId: widget.personId,
              currency: _selectedCurrency,
            ),
            icon: const Icon(LucideIcons.plus),
          ),
          PopupMenuButton<_PersonAction>(
            onSelected: (action) {
              switch (action) {
                case _PersonAction.delete:
                  _deletePerson(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _PersonAction.delete,
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2),
                    SizedBox(width: 10),
                    Text('حذف الشخص'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(AppError.message(error))),
        data: (data) {
          final matches = data.people.where(
            (item) => item.person.id == widget.personId,
          );
          if (matches.isEmpty) {
            return const Center(child: Text('الشخص غير موجود'));
          }

          final summary = matches.first;
          final txs = data.transactions
              .where((tx) => tx.personId == widget.personId)
              .toList();
          final selectedCurrency =
              _selectedCurrency ?? _firstCurrencyWithActivity(summary, txs);
          final selectedTxs = txs
              .where((tx) => tx.currency == selectedCurrency)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _PersonHeader(summary: summary),
              const SizedBox(height: 18),
              _CurrencyAccountsSection(
                summary: summary,
                transactions: txs,
                selectedCurrency: selectedCurrency,
                onSelected: (currency) {
                  setState(() => _selectedCurrency = currency);
                },
              ),
              const SizedBox(height: 14),
              _SelectedCurrencySummary(
                summary: summary,
                currency: selectedCurrency,
                transactionCount: selectedTxs.length,
                onAddTransaction: () => showTransactionFormSheet(
                  context,
                  personId: widget.personId,
                  currency: selectedCurrency,
                ),
                onEditPerson: () => showPersonFormSheet(
                  context,
                  person: summary.person,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'عمليات ${selectedCurrency.label}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              if (selectedTxs.isEmpty)
                _EmptyCurrencyTransactions(
                  currency: selectedCurrency,
                  onAddTransaction: () => showTransactionFormSheet(
                    context,
                    personId: widget.personId,
                    currency: selectedCurrency,
                  ),
                )
              else
                ...selectedTxs.map(
                  (tx) => _TransactionListTile(
                    transaction: tx,
                    subtitle: _transactionSubtitle(tx),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  MoneyCurrency _firstCurrencyWithActivity(
    PersonSummary summary,
    List<DebtTransaction> transactions,
  ) {
    return MoneyCurrency.values.firstWhere(
      (currency) =>
          summary.hasActivityIn(currency) ||
          transactions.any((tx) => tx.currency == currency),
      orElse: () => MoneyCurrency.yer,
    );
  }

  Future<void> _deletePerson(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف الشخص؟',
      message: 'سيتم حذف الشخص وكل عملياته.',
      confirmText: 'حذف',
    );
    if (!ok) return;
    try {
      await ref.read(debtControllerProvider.notifier).deletePerson(
            widget.personId,
          );
      if (context.mounted) context.pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.message(error))),
      );
    }
  }

  String _transactionSubtitle(DebtTransaction tx) {
    final parts = <String>[
      tx.note.trim().isEmpty ? 'عملية' : tx.note.trim(),
    ];
    if (tx.dueDate != null) {
      final prefix = tx.isOverdue ? 'متأخرة منذ' : 'تستحق في';
      parts.add('$prefix ${AppFormatters.date(tx.dueDate!)}');
    }
    return parts.join(' - ');
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.summary});

  final PersonSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          child: Text(summary.person.name.characters.first),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.person.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                summary.person.phone.isEmpty
                    ? summary.person.note
                    : summary.person.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyAccountsSection extends StatelessWidget {
  const _CurrencyAccountsSection({
    required this.summary,
    required this.transactions,
    required this.selectedCurrency,
    required this.onSelected,
  });

  final PersonSummary summary;
  final List<DebtTransaction> transactions;
  final MoneyCurrency selectedCurrency;
  final ValueChanged<MoneyCurrency> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الحسابات حسب العملة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر عملة لعرض رصيدها وسجلاتها فقط.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MoneyCurrency.values.map((currency) {
                  final txCount = transactions
                      .where((tx) => tx.currency == currency)
                      .length;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: _CurrencyAccountTile(
                      currency: currency,
                      balance: summary.balanceByCurrency[currency] ?? 0,
                      transactionCount: txCount,
                      selected: currency == selectedCurrency,
                      onTap: () => onSelected(currency),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyAccountTile extends StatelessWidget {
  const _CurrencyAccountTile({
    required this.currency,
    required this.balance,
    required this.transactionCount,
    required this.selected,
    required this.onTap,
  });

  final MoneyCurrency currency;
  final double balance;
  final int transactionCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final directionColor = balance > 0
        ? colors.error
        : balance < 0
            ? colors.primary
            : colors.outline;
    final borderColor = selected ? colors.primary : colors.outlineVariant;
    final direction = balance > 0
        ? 'عليك'
        : balance < 0
            ? 'لك'
            : 'صافي';

    return Material(
      color: selected
          ? colors.primaryContainer.withOpacity(.55)
          : colors.surfaceContainerHighest.withOpacity(.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 178,
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: directionColor.withOpacity(.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      currency.symbol,
                      style: TextStyle(
                        color: directionColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      currency.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppFormatters.amount(balance.abs()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: directionColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$direction - $transactionCount عملية',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedCurrencySummary extends StatelessWidget {
  const _SelectedCurrencySummary({
    required this.summary,
    required this.currency,
    required this.transactionCount,
    required this.onAddTransaction,
    required this.onEditPerson,
  });

  final PersonSummary summary;
  final MoneyCurrency currency;
  final int transactionCount;
  final VoidCallback onAddTransaction;
  final VoidCallback onEditPerson;

  @override
  Widget build(BuildContext context) {
    final debt = summary.debtByCurrency[currency] ?? 0;
    final payment = summary.paymentByCurrency[currency] ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص ${currency.label}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            CurrencyTotalsView(
              totals: {currency: summary.balanceByCurrency[currency] ?? 0},
              showDirection: true,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CurrencyStat(
                  label: 'إجمالي عليك',
                  value: AppFormatters.money(debt, currency),
                ),
                _CurrencyStat(
                  label: 'إجمالي لك',
                  value: AppFormatters.money(payment, currency),
                ),
                _CurrencyStat(
                  label: 'العمليات',
                  value: transactionCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAddTransaction,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('عملية'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditPerson,
                    icon: const Icon(LucideIcons.pencil),
                    label: const Text('تعديل'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyStat extends StatelessWidget {
  const _CurrencyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 118, minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionListTile extends StatelessWidget {
  const _TransactionListTile({
    required this.transaction,
    required this.subtitle,
  });

  final DebtTransaction transaction;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          transaction.type == DebtTransactionType.debt ? 'عليك' : 'لك',
        ),
        subtitle: Text(subtitle),
        leading: Icon(
          transaction.type == DebtTransactionType.debt
              ? LucideIcons.arrowUpRight
              : LucideIcons.arrowDownLeft,
        ),
        trailing: Text(
          AppFormatters.money(transaction.amount, transaction.currency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _EmptyCurrencyTransactions extends StatelessWidget {
  const _EmptyCurrencyTransactions({
    required this.currency,
    required this.onAddTransaction,
  });

  final MoneyCurrency currency;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(LucideIcons.walletCards, color: colors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'لا توجد عمليات ${currency.label}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'أضف عملية جديدة لهذه العملة بدون خلطها مع بقية الحسابات.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAddTransaction,
              icon: const Icon(LucideIcons.plus),
              label: const Text('إضافة عملية'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PersonAction { delete }
