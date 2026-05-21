import 'package:my_accounts/config/app_router.dart';
import 'package:my_accounts/config/app_theme.dart';
import 'package:my_accounts/core/constants/app_constants.dart';
import 'package:my_accounts/mvc/app_mvc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };
      await initializeDateFormatting('ar');
      await AppDatabase.instance.database;
      runApp(const ProviderScope(child: MyAccountsApp()));
    },
    (error, stackTrace) {
      if (!kReleaseMode) {
        debugPrint('Uncaught app error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    },
  );
}

class MyAccountsApp extends ConsumerWidget {
  const MyAccountsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        ErrorWidget.builder = (details) => Material(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'حدث خطأ غير متوقع في الواجهة',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
