import 'package:debt_ledger_app/presentation/auth/forgot_password_screen.dart';
import 'package:debt_ledger_app/presentation/auth/login_screen.dart';
import 'package:debt_ledger_app/presentation/auth/pin_lock_screen.dart';
import 'package:debt_ledger_app/presentation/auth/register_screen.dart';
import 'package:debt_ledger_app/presentation/notifications/notifications_screen.dart';
import 'package:debt_ledger_app/presentation/onboarding/onboarding_screen.dart';
import 'package:debt_ledger_app/presentation/people/person_detail_screen.dart';
import 'package:debt_ledger_app/presentation/settings/settings_screen.dart';
import 'package:debt_ledger_app/presentation/shared/app_providers.dart';
import 'package:debt_ledger_app/presentation/shell/app_shell.dart';
import 'package:debt_ledger_app/presentation/splash/splash_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final pin = ref.read(pinControllerProvider);
      if (auth.isLoading || pin.isLoading) return null;

      final path = state.uri.path;
      const publicPaths = {
        '/splash',
        '/onboarding',
        '/login',
        '/register',
        '/forgot-password',
      };

      final signedIn = auth.valueOrNull != null;
      final isPublic = publicPaths.contains(path);

      if (!signedIn && !isPublic) return '/login';
      if (signedIn && (path == '/login' || path == '/register')) return '/app';

      final needsPin = signedIn && pin.hasPin && !pin.unlocked;
      if (needsPin && path != '/pin-lock') return '/pin-lock';
      if (!needsPin && path == '/pin-lock') return signedIn ? '/app' : '/login';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/pin-lock', builder: (context, state) => const PinLockScreen()),
      GoRoute(path: '/app', builder: (context, state) => const AppShell()),
      GoRoute(
        path: '/person/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: PersonDetailScreen(personId: state.pathParameters['id']!),
          transitionsBuilder: _fadeSlide,
        ),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});

Widget _fadeSlide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(animation),
      child: child,
    ),
  );
}