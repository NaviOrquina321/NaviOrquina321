import '../db/database_helper.dart';
import '../models/models.dart';

class DoctorRepository {
  final DatabaseHelper dbHelper;

  DoctorRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Doctor>> getAllDoctors({String? searchQuery, String? specialty}) async {
    final db = await dbHelper.database;
    String sql = '''
      SELECT d.*, u.full_name, u.email, u.role, u.password_hash, u.salt, u.created_at as user_created_at
      FROM doctors d
      JOIN users u ON d.user_id = u.id
    ''';

    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(u.full_name LIKE ? OR d.specialty LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (specialty != null && specialty.trim().isNotEmpty && specialty.toLowerCase() != 'all') {
      whereClauses.add('d.specialty = ?');
      whereArgs.add(specialty.trim());
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    sql += ' ORDER BY d.rating DESC';

    final results = await db.rawQuery(sql, whereArgs);

    return results.map((row) {
      final user = User(
        id: row['user_id'] as int,
        role: row['role'] as String,
        fullName: row['full_name'] as String,
        email: row['email'] as String,
        passwordHash: row['password_hash'] as String,
        salt: row['salt'] as String,
        createdAt: row['user_created_at'] as String,
      );
      return Doctor.fromMap(row, user: user);
    }).toList();
  }

  Future<Doctor?> getDoctorByUserId(int userId) async {
    final db = await dbHelper.database;
    final results = await db.rawQuery('''
      SELECT d.*, u.full_name, u.email, u.role, u.password_hash, u.salt, u.created_at as user_created_at
      FROM doctors d
      JOIN users u ON d.user_id = u.id
      WHERE d.user_id = ?
    ''', [userId]);

    if (results.isEmpty) return null;

    final row = results.first;
    final user = User(
      id: row['user_id'] as int,
      role: row['role'] as String,
      fullName: row['full_name'] as String,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      salt: row['salt'] as String,
      createdAt: row['user_created_at'] as String,
    );

    return Doctor.fromMap(row, user: user);
  }

  Future<Doctor?> getDoctorById(int doctorId) async {
    final db = await dbHelper.database;
    final results = await db.rawQuery('''
      SELECT d.*, u.full_name, u.email, u.role, u.password_hash, u.salt, u.created_at as user_created_at
      FROM doctors d
      JOIN users u ON d.user_id = u.id
      WHERE d.id = ?
    ''', [doctorId]);

    if (results.isEmpty) return null;

    final row = results.first;
    final user = User(
      id: row['user_id'] as int,
      role: row['role'] as String,
      fullName: row['full_name'] as String,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      salt: row['salt'] as String,
      createdAt: row['user_created_at'] as String,
    );

    return Doctor.fromMap(row, user: user);
  }

  Future<List<String>> getAllSpecialties() async {
    final db = await dbHelper.database;
    final results = await db.rawQuery('SELECT DISTINCT specialty FROM doctors WHERE specialty IS NOT NULL');
    return results.map((r) => r['specialty'] as String).toList();
  }

  Future<void> updateDoctorProfile(int doctorId, {String? specialty, String? room, String? bio}) async {
    final db = await dbHelper.database;
    final Map<String, dynamic> updates = {};
    if (specialty != null) updates['specialty'] = specialty;
    if (room != null) updates['room'] = room;
    if (bio != null) updates['bio'] = bio;

    if (updates.isNotEmpty) {
      await db.update('doctors', updates, where: 'id = ?', whereArgs: [doctorId]);
    }
  }
}
