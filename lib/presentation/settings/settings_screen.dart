import 'package:my_accounts/core/constants/app_constants.dart';
import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: const [
            AppBrandLogo(size: 32),
            SizedBox(width: 10),
            Text('الإعدادات'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (v) => controller.setThemeMode(v!),
                  title: const Text('الوضع الفاتح'),
                  secondary: const Icon(LucideIcons.sun),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (v) => controller.setThemeMode(v!),
                  title: const Text('الوضع الداكن'),
                  secondary: const Icon(LucideIcons.moon),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(LucideIcons.languages),
              title: Text('تبديل اللغة'),
              subtitle: Text('جاهز لإضافة English لاحقًا'),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(LucideIcons.badgeCheck),
              title: Text('الحقوق'),
              subtitle: Text('© جميع الحقوق محفوظة'),
              trailing: Text(
                AppConstants.copyrightOwner,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
