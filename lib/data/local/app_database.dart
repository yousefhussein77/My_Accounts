import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;
  static const _dbName = 'my_accounts.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = join(await getDatabasesPath(), _dbName);
    _database = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE people (
            id TEXT PRIMARY KEY,
            owner_user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT,
            note TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE debt_transactions (
            id TEXT PRIMARY KEY,
            owner_user_id TEXT NOT NULL,
            person_id TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT NOT NULL DEFAULT 'yer',
            title TEXT NOT NULL,
            note TEXT,
            date TEXT NOT NULL,
            due_date TEXT,
            FOREIGN KEY(person_id) REFERENCES people(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE notifications (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE people ADD COLUMN owner_user_id TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE debt_transactions ADD COLUMN owner_user_id TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 3) {
          // Keep existing operational data during upgrades.
          // Historical resets can cause data loss for real users.
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE debt_transactions ADD COLUMN currency TEXT NOT NULL DEFAULT 'yer'",
          );
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return _database!;
  }
}
