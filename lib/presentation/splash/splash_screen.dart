import 'package:my_accounts/core/constants/app_constants.dart';
import 'package:my_accounts/core/utils/app_error.dart';
import 'package:my_accounts/core/widgets/app_brand_logo.dart';
import 'package:my_accounts/presentation/shared/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_route);
  }

  Future<void> _route() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await ref.read(authControllerProvider.notifier).load();
      if (!mounted) return;
      final firstLaunch =
          await ref.read(authControllerProvider.notifier).isFirstLaunch();
      final user = ref.read(authControllerProvider).valueOrNull;
      if (firstLaunch) {
        context.go('/onboarding');
      } else if (user == null) {
        context.go('/login');
      } else {
        context.go('/app');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.message(error))),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 1.05,
                  colors: [
                    colors.primary.withOpacity(0.16),
                    colors.surface,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.62),
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(0.07),
              ),
            ),
          ),
          Center(
            child: const AppBrandLogo(size: 238)
                .animate()
                .scale(duration: 500.ms)
                .fadeIn(),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, 0.79),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ديونك واضحة، وقراراتك أهدأ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
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
