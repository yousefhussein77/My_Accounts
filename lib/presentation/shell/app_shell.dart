import 'package:my_accounts/presentation/people/people_screen.dart';
import 'package:my_accounts/presentation/profile/profile_screen.dart';
import 'package:my_accounts/presentation/reports/reports_screen.dart';
import 'package:my_accounts/presentation/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    PeopleScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.users), label: 'الأشخاص'),
          NavigationDestination(icon: Icon(LucideIcons.receipt), label: 'السجل'),
          NavigationDestination(icon: Icon(LucideIcons.barChart3), label: 'التقارير'),
          NavigationDestination(icon: Icon(LucideIcons.userCircle), label: 'حسابي'),
        ],
      ),
    );
  }
}
