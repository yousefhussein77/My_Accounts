import 'package:debt_ledger_app/core/utils/app_error.dart';
import 'package:debt_ledger_app/core/utils/formatters.dart';
import 'package:debt_ledger_app/core/widgets/confirm_dialog.dart';
import 'package:debt_ledger_app/domain/models/debt_transaction.dart';
import 'package:debt_ledger_app/presentation/people/person_form_sheet.dart';
import 'package:debt_ledger_app/presentation/shared/app_providers.dart';
import 'package:debt_ledger_app/presentation/shared/currency_totals_view.dart';
import 'package:debt_ledger_app/presentation/transactions/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtControllerProvider);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => showTransactionFormSheet(context, personId: personId),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(AppError.message(error))),
        data: (data) {
          final matches = data.people.where((item) => item.person.id == personId);
          if (matches.isEmpty) return const Center(child: Text('الشخص غير موجود'));
          final summary = matches.first;
          final txs = data.transactions.where((tx) => tx.personId == personId).toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
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
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الرصيد الحالي'),
                      const SizedBox(height: 6),
                      CurrencyTotalsView(
                        totals: summary.balanceByCurrency,
                        showDirection: true,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => showTransactionFormSheet(
                                context,
                                personId: personId,
                              ),
                              icon: const Icon(LucideIcons.plus),
                              label: const Text('عملية'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => showPersonFormSheet(
                                context,
                                person: summary.person,
                              ),
                              icon: const Icon(LucideIcons.pencil),
                              label: const Text('تعديل'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'حذف الشخص؟',
                    message: 'سيتم حذف الشخص وكل عملياته.',
                    confirmText: 'حذف',
                  );
                  if (!ok) return;
                  try {
                    await ref.read(debtControllerProvider.notifier).deletePerson(personId);
                    if (context.mounted) context.pop();
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppError.message(error))),
                    );
                  }
                },
                icon: const Icon(LucideIcons.trash2),
                label: const Text('حذف الشخص'),
              ),
              const SizedBox(height: 22),
              Text(
                'العمليات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              ...txs.map(
                (tx) => Card(
                  child: ListTile(
                    title: Text(tx.type == DebtTransactionType.debt ? 'عليك' : 'لك'),
                    subtitle: Text(
                      tx.note.trim().isEmpty ? 'عملية' : tx.note.trim(),
                    ),
                    leading: Icon(
                      tx.type == DebtTransactionType.debt
                          ? LucideIcons.arrowUpRight
                          : LucideIcons.arrowDownLeft,
                    ),
                    trailing: Text(
                      AppFormatters.money(tx.amount, tx.currency),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
