# MVC Migration Guide

This project now uses a gradual MVC structure without breaking existing code.

## Current Mapping

- Model:
  `lib/domain/models/*`
  Re-exported through `lib/mvc/models/models.dart`

- View:
  `lib/presentation/*screen.dart`
  Re-exported through `lib/mvc/views/views.dart`

- Controller:
  Riverpod StateNotifiers in `lib/presentation/shared/app_providers.dart`
  Re-exported through `lib/mvc/controllers/controllers.dart`

- Service:
  Repositories and local persistence in `lib/data/*`
  Re-exported through `lib/mvc/services/services.dart`

## Rule For New Code

1. New screen logic goes through Controller classes/providers.
2. Controllers call Services/Repositories (or use cases) for data operations.
3. Views never access SQLite, SharedPreferences, or secure storage directly.
4. New imports should prefer:
   `import 'package:my_accounts/mvc/app_mvc.dart';`

## Why Gradual

This keeps the app stable while introducing a clear MVC entrypoint.
Existing files keep working, and new work follows one explicit pattern.
