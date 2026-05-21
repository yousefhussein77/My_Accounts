import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _GuidePage(
      icon: LucideIcons.userPlus,
      title: 'ابدأ بإضافة الأشخاص',
      description: 'أضف كل شخص تتعامل معه في صفحة الأشخاص.',
    ),
    _GuidePage(
      icon: LucideIcons.scale,
      title: 'سجّل العملية ببساطة',
      description: 'عند كل عملية اختر فقط: "لك" أو "عليك"، ثم أدخل المبلغ.',
    ),
    _GuidePage(
      icon: LucideIcons.layoutDashboard,
      title: 'راجع الحساب بسرعة',
      description: 'من الصفحة الرئيسية تتابع الرصيد والعمليات لكل شخص بسهولة.',
    ),
    _GuidePage(
      icon: LucideIcons.moonStar,
      title: 'غيّر الثيم متى شئت',
      description: 'زر الثيم ثابت في الهيدر للتبديل بين الفاتح والداكن بسرعة.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(authControllerProvider.notifier).finishOnboarding();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.7),
                  radius: 1.25,
                  colors: [
                    colors.primary.withAlpha(
                      (0.12 * 255).clamp(0, 255).toInt(),
                    ),
                    colors.surface,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -1.05),
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withAlpha(
                  (0.05 * 255).clamp(0, 255).toInt(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const AppBrandLogo(size: 72),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const SizedBox(width: 72, height: 40),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _finish,
                          child: const Text('تخطي'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, i) {
                        final page = _pages[i];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                page.icon,
                                size: 42,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? colors.primary
                              : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_index > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _controller.previousPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            },
                            child: const Text('السابق'),
                          ),
                        ),
                      if (_index > 0) const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (isLast) {
                              _finish();
                              return;
                            }
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Text(isLast ? 'ابدأ الآن' : 'التالي'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidePage {
  const _GuidePage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
