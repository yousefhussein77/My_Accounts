import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_accounts/core/widgets/app_empty_state.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:my_accounts/presentation/people/person_form_sheet.dart';
import 'package:my_accounts/presentation/people/person_summary_card.dart';
import 'package:my_accounts/presentation/shared/app_header.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:my_accounts/presentation/shared/currency_filter_bar.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  MoneyCurrency? _selectedCurrency;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtControllerProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPersonFormSheet(context),
        child: const Icon(LucideIcons.userPlus),
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (data) {
            final visiblePeople = data.visiblePeople;
            final people = _selectedCurrency == null
                ? visiblePeople
                : visiblePeople
                    .where((item) => item.hasActivityIn(_selectedCurrency!))
                    .toList();
            final currencyCounts = {
              for (final currency in MoneyCurrency.values)
                currency: visiblePeople
                    .where((item) => item.hasActivityIn(currency))
                    .length,
            };
            final sortLabel = _sortLabel(data.sort);

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const AppHeader(
                  title: 'الأشخاص',
                  subtitle: 'إدارة الأشخاص وحساباتهم حسب كل عملة.',
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: ref.read(debtControllerProvider.notifier).setQuery,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.search),
                    hintText: 'ابحث بالاسم أو رقم الهاتف',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PopupMenuButton<PeopleSort>(
                      onSelected:
                          ref.read(debtControllerProvider.notifier).setSort,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: PeopleSort.balance,
                          child: Text('حسب حجم الالتزامات'),
                        ),
                        PopupMenuItem(
                          value: PeopleSort.recent,
                          child: Text('حسب آخر نشاط'),
                        ),
                        PopupMenuItem(
                          value: PeopleSort.name,
                          child: Text('حسب الاسم'),
                        ),
                      ],
                      child: Chip(
                        avatar: const Icon(LucideIcons.arrowUpDown, size: 18),
                        label: Text('ترتيب: $sortLabel'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CurrencyFilterBar(
                  selectedCurrency: _selectedCurrency,
                  currencyCounts: currencyCounts,
                  totalCount: visiblePeople.length,
                  onSelected: (currency) {
                    setState(() => _selectedCurrency = currency);
                  },
                ),
                const SizedBox(height: 16),
                if (visiblePeople.isEmpty)
                  AppEmptyState(
                    icon: LucideIcons.users,
                    title: 'لا يوجد أشخاص',
                    message: 'أضف أول شخص للبدء في تسجيل العمليات.',
                    action: FilledButton.icon(
                      onPressed: () => showPersonFormSheet(context),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('إضافة شخص'),
                    ),
                  )
                else if (people.isEmpty)
                  AppEmptyState(
                    icon: LucideIcons.coins,
                    title: 'لا توجد حسابات ${_selectedCurrency!.label}',
                    message: 'اختر عملة أخرى أو أضف عملية بهذه العملة.',
                  )
                else
                  ...people.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PersonSummaryCard(
                        summary: item,
                        onTap: () => context.push('/person/${item.person.id}'),
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

  String _sortLabel(PeopleSort sort) {
    return switch (sort) {
      PeopleSort.balance => 'الالتزامات',
      PeopleSort.recent => 'آخر نشاط',
      PeopleSort.name => 'الاسم',
    };
  }
}
