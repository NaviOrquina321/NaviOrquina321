import '../db/database_helper.dart';
import '../models/models.dart';

class NotificationRepository {
  final DatabaseHelper dbHelper;

  NotificationRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<AppNotification>> getUserNotifications(int userId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((r) => AppNotification.fromMap(r)).toList();
  }

  Future<int> getUnreadCount(int userId) async {
    final db = await dbHelper.database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    if (results.isEmpty) return 0;
    return (results.first['count'] as int?) ?? 0;
  }

  Future<void> markAsRead(int notificationId) async {
    final db = await dbHelper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllAsRead(int userId) async {
    final db = await dbHelper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
  }

  Future<void> clearAllNotifications(int userId) async {
    final db = await dbHelper.database;
    await db.delete(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
