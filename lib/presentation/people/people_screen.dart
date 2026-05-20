import 'package:my_accounts/core/widgets/app_empty_state.dart';
import 'package:my_accounts/presentation/people/person_form_sheet.dart';
import 'package:my_accounts/presentation/people/person_summary_card.dart';
import 'package:my_accounts/presentation/shared/app_header.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            final people = data.visiblePeople;
            final sortLabel = _sortLabel(data.sort);
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const AppHeader(
                  title: 'الأشخاص',
                  subtitle: 'إدارة الأشخاص وعملياتهم بسهولة',
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
                PopupMenuButton<PeopleSort>(
                  onSelected: ref.read(debtControllerProvider.notifier).setSort,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: PeopleSort.balance,
                      child: Text('حسب حجم الالتزامات'),
                    ),
                    PopupMenuItem(
                      value: PeopleSort.recent,
                      child: Text('حسب آخر نشاط'),
                    ),
                    PopupMenuItem(value: PeopleSort.name, child: Text('حسب الاسم')),
                  ],
                  child: Chip(
                    avatar: const Icon(LucideIcons.arrowUpDown, size: 18),
                    label: Text('ترتيب: $sortLabel'),
                  ),
                ),
                const SizedBox(height: 16),
                if (people.isEmpty)
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
