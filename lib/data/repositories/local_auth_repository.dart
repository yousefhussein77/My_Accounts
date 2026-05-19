import 'package:debt_ledger_app/core/security/password_hasher.dart';
import 'package:debt_ledger_app/data/local/app_database.dart';
import 'package:debt_ledger_app/domain/models/app_user.dart';
import 'package:debt_ledger_app/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._database);

  final AppDatabase _database;
  static const _userIdKey = 'current_user_id';
  static const _onboardingKey = 'onboarding_seen';
  static const _loginAttemptsKey = 'login_failed_attempts';
  static const _loginLockedUntilKey = 'login_locked_until';
  static const _maxLoginAttempts = 5;
  static const _loginLockDuration = Duration(seconds: 60);

  @override
  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_userIdKey);
    if (id == null) return null;
    final db = await _database.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  @override
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }

  @override
  Future<AppUser> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilRaw = prefs.getString(_loginLockedUntilKey);
    final lockedUntil = lockedUntilRaw == null
        ? null
        : DateTime.tryParse(lockedUntilRaw);
    if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
      final seconds = lockedUntil.difference(DateTime.now()).inSeconds.clamp(1, 9999);
      throw Exception('محاولات كثيرة، حاول بعد $seconds ثانية');
    }

    final db = await _database.database;
    final normalizedEmail = email.trim().toLowerCase();
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (rows.isEmpty || !_passwordMatches(password, rows.first['password'])) {
      final attempts = (prefs.getInt(_loginAttemptsKey) ?? 0) + 1;
      await prefs.setInt(_loginAttemptsKey, attempts);
      if (attempts >= _maxLoginAttempts) {
        final newLockedUntil = DateTime.now().add(_loginLockDuration);
        await prefs.setString(_loginLockedUntilKey, newLockedUntil.toIso8601String());
      }
      throw Exception('البريد أو كلمة المرور غير صحيحة');
    }

    final storedPassword = rows.first['password'] as String;
    if (!PasswordHasher.isHash(storedPassword)) {
      await db.update(
        'users',
        {'password': PasswordHasher.hash(password)},
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
    }

    final user = AppUser.fromMap(rows.first);
    await prefs.setInt(_loginAttemptsKey, 0);
    await prefs.remove(_loginLockedUntilKey);
    await prefs.setString(_userIdKey, user.id);
    return user;
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    final db = await _database.database;
    final user = AppUser(
      id: const Uuid().v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
    try {
      await db.insert('users', {
        ...user.toMap(),
        'password': PasswordHasher.hash(password),
      });
    } catch (_) {
      throw Exception('يوجد حساب بهذا البريد مسبقًا');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await markOnboardingSeen();
    return user;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  @override
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  bool _passwordMatches(String password, Object? storedPassword) {
    if (storedPassword is! String || storedPassword.isEmpty) {
      return false;
    }
    if (!PasswordHasher.isHash(storedPassword)) {
      return storedPassword == password;
    }
    return PasswordHasher.verify(password, storedPassword);
  }
}
