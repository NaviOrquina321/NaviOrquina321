import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

class SettingsRepository {
  final DatabaseHelper dbHelper;

  SettingsRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<UserSettings> getUserSettings(int userId) async {
    final db = await dbHelper.database;
    final results = await db.query('settings', where: 'user_id = ?', whereArgs: [userId]);

    if (results.isEmpty) {
      final defaultSettings = UserSettings(userId: userId);
      await db.insert('settings', defaultSettings.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      return defaultSettings;
    }

    return UserSettings.fromMap(results.first);
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    final db = await dbHelper.database;
    await db.insert('settings', settings.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    final db = await dbHelper.database;
    final userRes = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (userRes.isEmpty) return false;

    final userMap = userRes.first;
    final salt = userMap['salt'] as String;
    final storedHash = userMap['password_hash'] as String;

    final computedHash = DatabaseHelper.hashPassword(oldPassword, salt);
    if (computedHash != storedHash) return false;

    final newHash = DatabaseHelper.hashPassword(newPassword, salt);
    await db.update(
      'users',
      {'password_hash': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return true;
  }

  Future<void> deleteAccount(int userId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
      await txn.delete('app_session');
    });
  }
}
