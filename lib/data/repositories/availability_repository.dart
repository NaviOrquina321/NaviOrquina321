import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

class AvailabilityRepository {
  final DatabaseHelper dbHelper;

  AvailabilityRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Availability>> getDoctorAvailability(int doctorId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'availability',
      where: 'doctor_id = ?',
      whereArgs: [doctorId],
      orderBy: 'weekday ASC',
    );
    return results.map((r) => Availability.fromMap(r)).toList();
  }

  Future<Availability?> getAvailabilityForDay(int doctorId, int weekday) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'availability',
      where: 'doctor_id = ? AND weekday = ?',
      whereArgs: [doctorId, weekday],
    );
    if (results.isEmpty) return null;
    return Availability.fromMap(results.first);
  }

  Future<void> saveDoctorAvailability(int doctorId, List<Availability> availabilities) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      for (final avail in availabilities) {
        await txn.insert(
          'availability',
          avail.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
