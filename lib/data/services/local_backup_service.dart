import 'dart:io';

import 'package:my_accounts/data/local/app_database.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalBackupService {
  LocalBackupService(this._database);

  final AppDatabase _database;

  Future<String> createBackup({String? directoryPath}) async {
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

      final fileName = _buildBackupFileName();
      final backupPath = join(backupDir.path, fileName);
      await dbFile.copy(backupPath);
      return backupPath;
    } finally {
      await _database.database;
    }
  }

  Future<void> restoreBackup(String backupFilePath) async {
    final backupFile = File(backupFilePath);
    if (!await backupFile.exists()) {
      throw Exception('ملف النسخة الاحتياطية غير موجود');
    }
    await _validateBackupSchema(backupFilePath);

    await _database.close();
    try {
      final dbPath = await _database.databasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final rollbackPath = '$dbPath.rollback';
        await dbFile.copy(rollbackPath);
      }
      await backupFile.copy(dbPath);
    } finally {
      await _database.database;
    }
  }

  Future<Directory> _resolveBackupDirectory(String? directoryPath) async {
    if (directoryPath != null && directoryPath.trim().isNotEmpty) {
      return Directory(directoryPath.trim());
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory(join(appDocDir.path, 'backups'));
  }

  Future<void> _validateBackupSchema(String backupPath) async {
    final db = await openDatabase(backupPath, readOnly: true);
    try {
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
    } finally {
      await db.close();
    }
  }

  String _buildBackupFileName() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return 'my_accounts_backup_${y}_$m_${d}_$h$min$s.db';
  }
}
