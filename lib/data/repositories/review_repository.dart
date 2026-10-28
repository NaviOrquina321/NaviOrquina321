import '../db/database_helper.dart';
import '../models/models.dart';

class ReviewRepository {
  final DatabaseHelper dbHelper;

  ReviewRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> submitReview({
    required int appointmentId,
    required int patientId,
    required int doctorId,
    required int rating,
    String? tags,
    String? comment,
  }) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert('reviews', {
        'appointment_id': appointmentId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'rating': rating,
        'tags': tags,
        'comment': comment,
        'created_at': nowStr,
      });

      final avgRes = await txn.rawQuery(
        'SELECT AVG(rating) as avg_rating FROM reviews WHERE doctor_id = ?',
        [doctorId],
      );

      if (avgRes.isNotEmpty && avgRes.first['avg_rating'] != null) {
        final newAvg = (avgRes.first['avg_rating'] as num).toDouble();
        await txn.update(
          'doctors',
          {'rating': double.parse(newAvg.toStringAsFixed(1))},
          where: 'id = ?',
          whereArgs: [doctorId],
        );
      }
    });
  }

  Future<List<Review>> getDoctorReviews(int doctorId) async {
    final db = await dbHelper.database;
    final results = await db.rawQuery('''
      SELECT r.*, u.full_name as patient_name
      FROM reviews r
      JOIN users u ON r.patient_id = u.id
      WHERE r.doctor_id = ?
      ORDER BY r.created_at DESC
    ''', [doctorId]);

    return results.map((row) {
      final patientUser = User(
        id: row['patient_id'] as int,
        role: 'patient',
        fullName: row['patient_name'] as String,
        email: '',
        passwordHash: '',
        salt: '',
        createdAt: '',
      );
      return Review.fromMap(row, patientUser: patientUser);
    }).toList();
  }

  Future<bool> isAppointmentReviewed(int appointmentId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'reviews',
      where: 'appointment_id = ?',
      whereArgs: [appointmentId],
    );
    return results.isNotEmpty;
  }
}
