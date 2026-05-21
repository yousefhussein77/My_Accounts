import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showLogo = true,
    this.showThemeToggle = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showLogo;
  final bool showThemeToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final isDark = settings.themeMode == ThemeMode.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLogo) ...[
          const AppBrandLogo(size: 44),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
        if (showThemeToggle)
          SizedBox.square(
            dimension: 44,
            child: IconButton(
              tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
              onPressed: () {
                controller.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
              },
              icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon),
            ),
          ),
      ],
    );
  }
}
