import 'package:my_accounts/core/widgets/app_empty_state.dart';
import 'package:my_accounts/presentation/shared/app_header.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:my_accounts/presentation/transactions/transaction_card.dart';
import 'package:my_accounts/presentation/transactions/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtControllerProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionFormSheet(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (data) => ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const AppHeader(
                title: 'العمليات',
                subtitle: 'كل العمليات في قائمة واحدة واضحة',
              ),
              const SizedBox(height: 16),
              if (data.transactions.isEmpty)
                const AppEmptyState(
                  icon: LucideIcons.receipt,
                  title: 'لا توجد عمليات',
                  message: 'ابدأ بإضافة عملية جديدة: لك أو عليك.',
                )
              else
                ...data.transactions.map((tx) {
                  final person = data.people.where(
                    (item) => item.person.id == tx.personId,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TransactionCard(
                      transaction: tx,
                      personName: person.isEmpty ? 'شخص محذوف' : person.first.person.name,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
