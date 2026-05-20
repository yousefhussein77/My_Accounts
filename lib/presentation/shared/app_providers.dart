import 'package:my_accounts/data/local/app_database.dart';
import 'package:my_accounts/data/repositories/local_auth_repository.dart';
import 'package:my_accounts/data/repositories/sqlite_debt_repository.dart';
import 'package:my_accounts/data/services/local_backup_service.dart';
import 'package:my_accounts/core/security/password_hasher.dart';
import 'package:my_accounts/domain/models/app_notification.dart';
import 'package:my_accounts/domain/models/app_user.dart';
import 'package:my_accounts/domain/models/debt_transaction.dart';
import 'package:my_accounts/domain/models/money_currency.dart';
import 'package:my_accounts/domain/models/person_summary.dart';
import 'package:my_accounts/domain/repositories/auth_repository.dart';
import 'package:my_accounts/domain/repositories/debt_repository.dart';
import 'package:my_accounts/domain/usecases/usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(ref.watch(databaseProvider)),
);

final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) => SqliteDebtRepository(ref.watch(databaseProvider)),
);

final backupServiceProvider = Provider<LocalBackupService>(
  (ref) => LocalBackupService(ref.watch(databaseProvider)),
);

final createBackupUseCaseProvider = Provider<CreateBackupUseCase>(
  (ref) => CreateBackupUseCase(ref.watch(backupServiceProvider)),
);

final restoreBackupUseCaseProvider = Provider<RestoreBackupUseCase>(
  (ref) => RestoreBackupUseCase(ref.watch(backupServiceProvider)),
);

final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>(
  (ref) => AddTransactionUseCase(ref.watch(debtRepositoryProvider)),
);

final savePersonUseCaseProvider = Provider<SavePersonUseCase>(
  (ref) => SavePersonUseCase(ref.watch(debtRepositoryProvider)),
);

final deletePersonUseCaseProvider = Provider<DeletePersonUseCase>(
  (ref) => DeletePersonUseCase(ref.watch(debtRepositoryProvider)),
);

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>(
  (ref) => DeleteTransactionUseCase(ref.watch(debtRepositoryProvider)),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final AuthRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.currentUser);
  }

  Future<bool> isFirstLaunch() => _repository.isFirstLaunch();

  Future<void> finishOnboarding() => _repository.markOnboardingSeen();

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.login(email, password));
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.register(name, email, password));
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final pinControllerProvider =
    StateNotifierProvider<PinController, PinState>((ref) {
  return PinController();
});

class PinState {
  static const _noChange = Object();

  const PinState({
    this.isLoading = true,
    this.hasPin = false,
    this.unlocked = false,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final bool isLoading;
  final bool hasPin;
  final bool unlocked;
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  PinState copyWith({
    bool? isLoading,
    bool? hasPin,
    bool? unlocked,
    int? failedAttempts,
    Object? lockedUntil = _noChange,
  }) {
    return PinState(
      isLoading: isLoading ?? this.isLoading,
      hasPin: hasPin ?? this.hasPin,
      unlocked: unlocked ?? this.unlocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: identical(lockedUntil, _noChange)
          ? this.lockedUntil
          : lockedUntil as DateTime?,
    );
  }
}

class PinController extends StateNotifier<PinState> {
  PinController() : super(const PinState()) {
    _load();
  }

  static const _pinKey = 'app_pin';
  static const _pinAttemptsKey = 'app_pin_attempts';
  static const _pinLockedUntilKey = 'app_pin_locked_until';
  static const _maxFailedAttempts = 5;
  static const _lockDuration = Duration(seconds: 60);
  static const _secureStorage = FlutterSecureStorage();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = await _readPinHash(prefs);
    final lockedUntilRaw = prefs.getString(_pinLockedUntilKey);
    final lockedUntil = lockedUntilRaw == null
        ? null
        : DateTime.tryParse(lockedUntilRaw);

    if (lockedUntil != null && lockedUntil.isBefore(DateTime.now())) {
      await prefs.remove(_pinLockedUntilKey);
      await prefs.setInt(_pinAttemptsKey, 0);
    }

    state = state.copyWith(
      isLoading: false,
      hasPin: pin != null && pin.isNotEmpty,
      unlocked: pin == null || pin.isEmpty,
      failedAttempts: prefs.getInt(_pinAttemptsKey) ?? 0,
      lockedUntil: lockedUntil != null && lockedUntil.isAfter(DateTime.now())
          ? lockedUntil
          : null,
    );
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _pinKey, value: PasswordHasher.hash(pin));
    await prefs.remove(_pinKey);
    await prefs.setInt(_pinAttemptsKey, 0);
    await prefs.remove(_pinLockedUntilKey);
    state = state.copyWith(
      hasPin: true,
      unlocked: true,
      isLoading: false,
      failedAttempts: 0,
      lockedUntil: null,
    );
  }

  Future<bool> verify(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await _readPinHash(prefs) ?? '';
    final lockedUntilRaw = prefs.getString(_pinLockedUntilKey);
    final lockedUntil = lockedUntilRaw == null
        ? null
        : DateTime.tryParse(lockedUntilRaw);

    if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
      state = state.copyWith(
        isLoading: false,
        lockedUntil: lockedUntil,
        failedAttempts: prefs.getInt(_pinAttemptsKey) ?? 0,
      );
      return false;
    }

    var ok = false;
    if (saved.isNotEmpty) {
      if (PasswordHasher.isHash(saved)) {
        ok = PasswordHasher.verify(pin, saved);
      } else {
        ok = saved == pin;
        if (ok) {
          await _secureStorage.write(
            key: _pinKey,
            value: PasswordHasher.hash(pin),
          );
          await prefs.remove(_pinKey);
        }
      }
    }

    if (ok) {
      await prefs.setInt(_pinAttemptsKey, 0);
      await prefs.remove(_pinLockedUntilKey);
      state = state.copyWith(unlocked: true, hasPin: true, isLoading: false);
      return true;
    }

    final attempts = (prefs.getInt(_pinAttemptsKey) ?? 0) + 1;
    await prefs.setInt(_pinAttemptsKey, attempts);
    if (attempts >= _maxFailedAttempts) {
      final newLockedUntil = DateTime.now().add(_lockDuration);
      await prefs.setString(_pinLockedUntilKey, newLockedUntil.toIso8601String());
      state = state.copyWith(
        failedAttempts: attempts,
        lockedUntil: newLockedUntil,
        unlocked: false,
        hasPin: saved.isNotEmpty,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        failedAttempts: attempts,
        lockedUntil: null,
        unlocked: false,
        hasPin: saved.isNotEmpty,
        isLoading: false,
      );
    }
    return false;
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _pinKey);
    await prefs.remove(_pinKey);
    await prefs.remove(_pinLockedUntilKey);
    await prefs.setInt(_pinAttemptsKey, 0);
    state = state.copyWith(
      hasPin: false,
      unlocked: true,
      isLoading: false,
      failedAttempts: 0,
      lockedUntil: null,
    );
  }

  void lock() {
    if (state.hasPin) {
      state = state.copyWith(unlocked: false);
    }
  }

  Future<String?> _readPinHash(SharedPreferences prefs) async {
    final securePin = await _secureStorage.read(key: _pinKey);
    if (securePin != null && securePin.isNotEmpty) return securePin;

    final legacyPin = prefs.getString(_pinKey);
    if (legacyPin == null || legacyPin.isEmpty) return null;

    await _secureStorage.write(key: _pinKey, value: legacyPin);
    await prefs.remove(_pinKey);
    return legacyPin;
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.language = 'العربية',
    this.reminderDays = 3,
    this.lastBackupAt,
    this.lastBackupPath,
  });

  final ThemeMode themeMode;
  final String language;
  final int reminderDays;
  final DateTime? lastBackupAt;
  final String? lastBackupPath;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    int? reminderDays,
    DateTime? lastBackupAt,
    String? lastBackupPath,
    bool clearBackupMeta = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      reminderDays: reminderDays ?? this.reminderDays,
      lastBackupAt: clearBackupMeta
          ? null
          : (lastBackupAt ?? this.lastBackupAt),
      lastBackupPath: clearBackupMeta
          ? null
          : (lastBackupPath ?? this.lastBackupPath),
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _load();
  }

  static const _themeKey = 'theme_mode';
  static const _reminderKey = 'reminder_days';
  static const _lastBackupAtKey = 'last_backup_at';
  static const _lastBackupPathKey = 'last_backup_path';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? ThemeMode.light.name;
    final mode = themeName == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
    final backupAtRaw = prefs.getString(_lastBackupAtKey);
    final backupAt = backupAtRaw == null ? null : DateTime.tryParse(backupAtRaw);
    state = state.copyWith(
      themeMode: mode,
      reminderDays: prefs.getInt(_reminderKey) ?? 3,
      lastBackupAt: backupAt,
      lastBackupPath: prefs.getString(_lastBackupPathKey),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setReminderDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderKey, days);
    state = state.copyWith(reminderDays: days);
  }

  Future<void> setLastBackupMeta({
    required DateTime at,
    required String path,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupAtKey, at.toIso8601String());
    await prefs.setString(_lastBackupPathKey, path);
    state = state.copyWith(lastBackupAt: at, lastBackupPath: path);
  }
}

final debtControllerProvider =
    StateNotifierProvider<DebtController, AsyncValue<DebtState>>((ref) {
  return DebtController(
    ref.watch(debtRepositoryProvider),
    ref.watch(addTransactionUseCaseProvider),
    ref.watch(savePersonUseCaseProvider),
    ref.watch(deletePersonUseCaseProvider),
    ref.watch(deleteTransactionUseCaseProvider),
    ref,
  );
});

class DebtState {
  const DebtState({
    this.people = const [],
    this.transactions = const [],
    this.query = '',
    this.sort = PeopleSort.balance,
  });

  final List<PersonSummary> people;
  final List<DebtTransaction> transactions;
  final String query;
  final PeopleSort sort;

  int get overdueCount => transactions.where((tx) => tx.isOverdue).length;

  List<PersonSummary> get visiblePeople {
    Iterable<PersonSummary> result = people;

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((item) {
        return item.person.name.toLowerCase().contains(q) ||
            item.person.phone.toLowerCase().contains(q);
      });
    }

    final list = result.toList();
    list.sort((a, b) {
      return switch (sort) {
        PeopleSort.name => a.person.name.compareTo(b.person.name),
        PeopleSort.recent =>
          (b.lastActivity ?? b.person.createdAt).compareTo(a.lastActivity ?? a.person.createdAt),
        PeopleSort.balance => b.exposureScore.compareTo(a.exposureScore),
      };
    });
    return list;
  }

  DebtState copyWith({
    List<PersonSummary>? people,
    List<DebtTransaction>? transactions,
    String? query,
    PeopleSort? sort,
  }) {
    return DebtState(
      people: people ?? this.people,
      transactions: transactions ?? this.transactions,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}

enum PeopleSort { balance, recent, name }

class DebtController extends StateNotifier<AsyncValue<DebtState>> {
  DebtController(
    this._repository,
    this._addTransaction,
    this._savePerson,
    this._deletePerson,
    this._deleteTransaction,
    this._ref,
  )
      : super(const AsyncValue.loading()) {
    refresh();
  }

  final DebtRepository _repository;
  final AddTransactionUseCase _addTransaction;
  final SavePersonUseCase _savePerson;
  final DeletePersonUseCase _deletePerson;
  final DeleteTransactionUseCase _deleteTransaction;
  final Ref _ref;
  
  String? _currentUserId() => _ref.read(authControllerProvider).valueOrNull?.id;

  Future<void> refresh() async {
    final previous = state.valueOrNull ?? const DebtState();
    state = AsyncValue.data(previous);

    try {
      final userId = _currentUserId();
      if (userId == null) {
        state = const AsyncValue.data(DebtState());
        return;
      }
      final people = await _repository.people(userId);
      final transactions = await _repository.transactions(userId);
      state = AsyncValue.data(previous.copyWith(
        people: people,
        transactions: transactions,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void setQuery(String query) {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncValue.data(value.copyWith(query: query));
    }
  }

  void setSort(PeopleSort sort) {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncValue.data(value.copyWith(sort: sort));
    }
  }

  Future<void> savePerson({
    String? id,
    required String name,
    String phone = '',
    String note = '',
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }
    final existing = state.valueOrNull?.people
        .where((item) => item.person.id == id)
        .map((item) => item.person)
        .toList();

    await _savePerson.execute(
      SavePersonInput(
        userId: userId,
        personId: id,
        name: name,
        phone: phone,
        note: note,
        existingPerson: existing == null || existing.isEmpty ? null : existing.first,
      ),
    );

    await refresh();
  }

  Future<void> deletePerson(String id) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }
    await _deletePerson.execute(userId: userId, personId: id);
    await refresh();
  }

  Future<void> addTransaction({
    required String personId,
    required DebtTransactionType type,
    required double amount,
    required MoneyCurrency currency,
    required String title,
    String note = '',
    DateTime? dueDate,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }
    await _addTransaction.execute(
      AddTransactionInput(
        userId: userId,
        personId: personId,
        type: type,
        amount: amount,
        currency: currency,
        title: title,
        note: note,
        dueDate: dueDate,
      ),
    );

    await refresh();
  }

  Future<void> deleteTransaction(String id) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }
    await _deleteTransaction.execute(userId: userId, transactionId: id);
    await refresh();
  }

  List<AppNotification> notifications() {
    return const [];
  }
}
