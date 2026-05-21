import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:my_accounts/data/local/app_database.dart';
import 'package:my_accounts/domain/models/backup_file_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class RestoreBackupResult {
  const RestoreBackupResult({this.safetyBackupPath});

  final String? safetyBackupPath;
}

class _PreparedBackup {
  const _PreparedBackup({required this.validatedPath, this.tempFile});

  final String validatedPath;
  final File? tempFile;
}

class LocalBackupService {
  LocalBackupService(this._database);

  final AppDatabase _database;

  static const _encryptedExt = '.mabk';
  static const _plainExt = '.db';
  static const _maxBackupBytes = 100 * 1024 * 1024; // 100 MB
  static const _maxDefaultBackups = 10;

  Future<String> createBackup({String? directoryPath, String? password}) async {
    await _database.database;
    await _database.close();
    try {
      final dbPath = await _database.databasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('لا توجد بيانات لحفظ نسخة احتياطية');
      }

      final backupDir = await _resolveBackupDirectory(directoryPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = _buildBackupFileName(
        encrypted: password != null && password.trim().isNotEmpty,
      );
      final backupPath = join(backupDir.path, fileName);

      if (password == null || password.trim().isEmpty) {
        await dbFile.copy(backupPath);
      } else {
        final plainBytes = await dbFile.readAsBytes();
        final encryptedBytes = await _encryptBytes(plainBytes, password.trim());
        await File(backupPath).writeAsBytes(encryptedBytes, flush: true);
      }

      if (directoryPath == null || directoryPath.trim().isEmpty) {
        try {
          await _cleanupOldDefaultBackups(backupDir, keepPath: backupPath);
        } catch (_) {
          // Backup creation should still succeed if old-file cleanup fails.
        }
      }

      return backupPath;
    } finally {
      await _database.database;
    }
  }

  Future<RestoreBackupResult> restoreBackup(
    String backupFilePath, {
    String? password,
  }) async {
    final prepared = await _prepareBackupForValidation(
      backupFilePath,
      password: password,
    );
    final validatedPath = prepared.validatedPath;
    final tempDecryptedFile = prepared.tempFile;
    String? safetyBackupPath;

    try {
      await _validateBackupSchema(validatedPath);

      await _database.close();
      final dbPath = await _database.databasePath();
      final currentDbPath = normalize(absolute(dbPath));
      final selectedPath = normalize(absolute(validatedPath));
      if (currentDbPath == selectedPath) {
        throw Exception('لا يمكن استعادة نفس قاعدة البيانات الحالية');
      }

      final dbFile = File(dbPath);
      final rollbackFile = File('$dbPath.rollback');
      var hasRollback = false;

      if (await rollbackFile.exists()) {
        await rollbackFile.delete();
      }
      if (await dbFile.exists()) {
        safetyBackupPath = await _createPreRestoreBackup(dbFile);
        await dbFile.copy(rollbackFile.path);
        hasRollback = true;
      }

      try {
        await File(validatedPath).copy(dbPath);
        await _validateBackupSchema(dbPath);
      } catch (_) {
        if (hasRollback && await rollbackFile.exists()) {
          await rollbackFile.copy(dbPath);
        }
        rethrow;
      } finally {
        if (await rollbackFile.exists()) {
          await rollbackFile.delete();
        }
      }
    } finally {
      if (tempDecryptedFile != null && await tempDecryptedFile.exists()) {
        await tempDecryptedFile.delete();
      }
      await _database.database;
    }
    return RestoreBackupResult(safetyBackupPath: safetyBackupPath);
  }

  Future<void> validateBackup(String backupFilePath, {String? password}) async {
    final prepared = await _prepareBackupForValidation(
      backupFilePath,
      password: password,
    );
    try {
      await _validateBackupSchema(prepared.validatedPath);
    } finally {
      final tempFile = prepared.tempFile;
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<List<BackupFileInfo>> defaultBackups() async {
    final backupDir = await _resolveBackupDirectory(null);
    if (!await backupDir.exists()) return const [];

    final backups = <BackupFileInfo>[];
    await for (final entity in backupDir.list()) {
      if (entity is! File) continue;

      final fileName = basename(entity.path);
      if (!_isManagedBackupFile(fileName.toLowerCase())) continue;

      final stat = await entity.stat();
      backups.add(
        BackupFileInfo(
          path: entity.path,
          fileName: fileName,
          modifiedAt: stat.modified,
          sizeBytes: stat.size,
          isEncrypted: fileName.toLowerCase().endsWith(_encryptedExt),
          isSafetyCopy: fileName.toLowerCase().startsWith(
            'my_accounts_pre_restore_',
          ),
        ),
      );
    }

    backups.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return backups;
  }

  Future<void> deleteDefaultBackup(String backupPath) async {
    final backupDir = await _resolveBackupDirectory(null);
    final backupDirPath = normalize(absolute(backupDir.path));
    final targetPath = normalize(absolute(backupPath));

    if (!isWithin(backupDirPath, targetPath)) {
      throw Exception('لا يمكن حذف ملف خارج مجلد النسخ الافتراضي');
    }

    final fileName = basename(targetPath).toLowerCase();
    if (!_isManagedBackupFile(fileName)) {
      throw Exception('لا يمكن حذف ملف غير تابع لنسخ التطبيق');
    }

    final file = File(targetPath);
    if (!await file.exists()) {
      throw Exception('ملف النسخة غير موجود');
    }

    await file.delete();
  }

  Future<_PreparedBackup> _prepareBackupForValidation(
    String backupFilePath, {
    String? password,
  }) async {
    final backupFile = File(backupFilePath);
    await _validateBackupInput(backupFilePath, backupFile);

    final isEncrypted = backupFilePath.toLowerCase().endsWith(_encryptedExt);
    if (!isEncrypted) {
      return _PreparedBackup(validatedPath: backupFilePath);
    }

    if (password == null || password.trim().isEmpty) {
      throw Exception('كلمة المرور مطلوبة لاستعادة النسخة المشفرة');
    }

    final encryptedBytes = await backupFile.readAsBytes();
    final plainBytes = await _decryptBytes(encryptedBytes, password.trim());
    final tempDir = await getTemporaryDirectory();
    final tempDecryptedFile = File(
      join(
        tempDir.path,
        'restore_${DateTime.now().millisecondsSinceEpoch}$_plainExt',
      ),
    );
    await tempDecryptedFile.writeAsBytes(plainBytes, flush: true);
    return _PreparedBackup(
      validatedPath: tempDecryptedFile.path,
      tempFile: tempDecryptedFile,
    );
  }

  Future<Directory> _resolveBackupDirectory(String? directoryPath) async {
    if (directoryPath != null && directoryPath.trim().isNotEmpty) {
      return Directory(directoryPath.trim());
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory(join(appDocDir.path, 'backups'));
  }

  Future<String> _createPreRestoreBackup(File dbFile) async {
    final backupDir = await _resolveBackupDirectory(null);
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final path = join(backupDir.path, _buildPreRestoreBackupFileName());
    await dbFile.copy(path);
    try {
      await _cleanupOldDefaultBackups(backupDir, keepPath: path);
    } catch (_) {
      // The safety copy was created; cleanup should not block restore.
    }
    return path;
  }

  Future<void> _validateBackupSchema(String backupPath) async {
    Database? db;
    try {
      db = await openDatabase(backupPath, readOnly: true);
      await _validateDatabaseIntegrity(db);

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );

      final tableNames = rows
          .map((row) => (row['name'] as String?) ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();

      const required = {'users', 'people', 'debt_transactions'};
      if (!tableNames.containsAll(required)) {
        throw Exception('ملف النسخة غير صالح للاستعادة');
      }

      await _validateRequiredColumns(db);
      await _validateForeignKeys(db);
    } on DatabaseException {
      throw Exception('الملف المختار ليس نسخة احتياطية صالحة');
    } finally {
      await db?.close();
    }
  }

  Future<void> _validateDatabaseIntegrity(Database db) async {
    final result = await db.rawQuery('PRAGMA integrity_check');
    final value = result.isEmpty ? null : result.first.values.first;
    if (value?.toString().toLowerCase() != 'ok') {
      throw Exception('ملف النسخة تالف ولا يمكن استعادته');
    }
  }

  Future<void> _validateRequiredColumns(Database db) async {
    const requiredColumns = {
      'users': {'id', 'name', 'email', 'password', 'created_at'},
      'people': {
        'id',
        'owner_user_id',
        'name',
        'phone',
        'note',
        'is_favorite',
        'created_at',
      },
      'debt_transactions': {
        'id',
        'owner_user_id',
        'person_id',
        'type',
        'amount',
        'currency',
        'title',
        'note',
        'date',
        'due_date',
      },
    };

    for (final entry in requiredColumns.entries) {
      final columns = await _tableColumns(db, entry.key);
      if (!columns.containsAll(entry.value)) {
        throw Exception('ملف النسخة غير متوافق مع إصدار التطبيق الحالي');
      }
    }
  }

  Future<Set<String>> _tableColumns(Database db, String tableName) async {
    final rows = await db.rawQuery('PRAGMA table_info($tableName)');
    return rows
        .map((row) => (row['name'] as String?) ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  Future<void> _validateForeignKeys(Database db) async {
    final rows = await db.rawQuery('PRAGMA foreign_key_check');
    if (rows.isNotEmpty) {
      throw Exception('ملف النسخة يحتوي على بيانات مرتبطة بشكل غير صالح');
    }
  }

  Future<void> _validateBackupInput(
    String backupFilePath,
    File backupFile,
  ) async {
    if (!await backupFile.exists()) {
      throw Exception('ملف النسخة الاحتياطية غير موجود');
    }

    final normalized = backupFilePath.toLowerCase().trim();
    final isSupported =
        normalized.endsWith(_plainExt) || normalized.endsWith(_encryptedExt);
    if (!isSupported) {
      throw Exception('امتداد الملف غير مدعوم. اختر ملف db أو mabk');
    }

    final size = await backupFile.length();
    if (size <= 0) {
      throw Exception('ملف النسخة فارغ');
    }
    if (size > _maxBackupBytes) {
      throw Exception('حجم ملف النسخة كبير جدا وغير متوقع');
    }
  }

  Future<void> _cleanupOldDefaultBackups(
    Directory backupDir, {
    required String keepPath,
  }) async {
    final keep = normalize(absolute(keepPath));
    final files = <File>[];

    await for (final entity in backupDir.list()) {
      if (entity is! File) continue;

      final name = basename(entity.path).toLowerCase();
      final isBackup = _isManagedBackupFile(name);
      if (isBackup) {
        files.add(entity);
      }
    }

    if (files.length <= _maxDefaultBackups) return;

    files.sort((a, b) {
      return b.lastModifiedSync().compareTo(a.lastModifiedSync());
    });

    for (final file in files.skip(_maxDefaultBackups)) {
      if (normalize(absolute(file.path)) == keep) continue;
      await file.delete();
    }
  }

  bool _isManagedBackupFile(String fileName) {
    final hasSupportedExtension =
        fileName.endsWith(_plainExt) || fileName.endsWith(_encryptedExt);
    final hasManagedPrefix =
        fileName.startsWith('my_accounts_backup_') ||
        fileName.startsWith('my_accounts_pre_restore_');
    return hasManagedPrefix && hasSupportedExtension;
  }

  String _buildBackupFileName({required bool encrypted}) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final ext = encrypted ? _encryptedExt : _plainExt;
    final timestamp =
        '$y'
        '_'
        '$m'
        '_'
        '$d'
        '_'
        '$h$min$s';
    return 'my_accounts_backup_$timestamp$ext';
  }

  String _buildPreRestoreBackupFileName() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final timestamp =
        '$y'
        '_'
        '$m'
        '_'
        '$d'
        '_'
        '$h$min$s';
    return 'my_accounts_pre_restore_$timestamp$_plainExt';
  }

  Future<Uint8List> _encryptBytes(List<int> plainBytes, String password) async {
    final algorithm = AesGcm.with256bits();
    final salt = algorithm.newNonce();
    final nonce = algorithm.newNonce();
    final secretKey = await _deriveKey(password, salt);
    final box = await algorithm.encrypt(
      plainBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final payload = jsonEncode({
      'v': 1,
      'alg': 'aes-gcm-256',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
    return Uint8List.fromList(utf8.encode(payload));
  }

  Future<Uint8List> _decryptBytes(
    List<int> encryptedBytes,
    String password,
  ) async {
    try {
      final raw = utf8.decode(encryptedBytes);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _validateEncryptedPayload(map);

      final salt = base64Decode(map['salt'] as String);
      final nonce = base64Decode(map['nonce'] as String);
      final cipher = base64Decode(map['cipher'] as String);
      final macBytes = base64Decode(map['mac'] as String);

      final secretKey = await _deriveKey(password, salt);
      final algorithm = AesGcm.with256bits();
      final clear = await algorithm.decrypt(
        SecretBox(cipher, nonce: nonce, mac: Mac(macBytes)),
        secretKey: secretKey,
      );
      return Uint8List.fromList(clear);
    } catch (_) {
      throw Exception('فشل فك تشفير النسخة. تحقق من كلمة المرور');
    }
  }

  void _validateEncryptedPayload(Map<String, dynamic> map) {
    final version = map['v'];
    final algorithm = map['alg'];
    if (version != 1 || algorithm != 'aes-gcm-256') {
      throw const FormatException('Unsupported backup format');
    }

    for (final key in const ['salt', 'nonce', 'cipher', 'mac']) {
      final value = map[key];
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Invalid encrypted backup payload');
      }
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }
}
