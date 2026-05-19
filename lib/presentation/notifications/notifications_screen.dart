import 'package:my_accounts/core/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات')),
      body: const AppEmptyState(
        icon: LucideIcons.bellOff,
        title: 'لا توجد تنبيهات',
        message: 'التطبيق يعمل الآن بدون نظام استحقاق.',
      ),
    );
  }
}
