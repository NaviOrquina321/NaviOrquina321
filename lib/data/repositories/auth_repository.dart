import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

class AuthRepository {
  final DatabaseHelper dbHelper;

  AuthRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<User?> getUserById(int userId) async {
    final db = await dbHelper.database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (res.isEmpty) return null;
    return User.fromMap(res.first);
  }

  Future<void> updateProfilePhoto(int userId, String? localSourcePath) async {
    final db = await dbHelper.database;
    final userRes = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (userRes.isEmpty) return;

    final existingPhoto = userRes.first['photo_path'] as String?;
    final docsDir = await getApplicationDocumentsDirectory();

    // Delete existing photo file if present
    if (existingPhoto != null && existingPhoto.isNotEmpty) {
      final oldFile = File('${docsDir.path}/$existingPhoto');
      if (oldFile.existsSync()) {
        try {
          oldFile.deleteSync();
        } catch (_) {}
      }
    }

    String? savedFileName;
    if (localSourcePath != null && localSourcePath.isNotEmpty) {
      final sourceFile = File(localSourcePath);
      if (sourceFile.existsSync()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        savedFileName = 'profile_${userId}_$timestamp.jpg';
        final targetPath = '${docsDir.path}/$savedFileName';
        await sourceFile.copy(targetPath);
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    await db.update(
      'users',
      {
        'photo_path': savedFileName,
        'photo_updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<User?> login(String email, String password, String expectedRole) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'users',
      where: 'email = ? AND role = ?',
      whereArgs: [email.trim().toLowerCase(), expectedRole],
    );

    if (results.isEmpty) return null;

    final userMap = results.first;
    final storedHash = userMap['password_hash'] as String;
    final salt = userMap['salt'] as String;

    final computedHash = DatabaseHelper.hashPassword(password, salt);
    if (computedHash == storedHash) {
      final user = User.fromMap(userMap);
      await saveSession(user.id!, user.role);
      return user;
    }
    return null;
  }

  Future<User> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? specialty,
    String? room,
  }) async {
    final db = await dbHelper.database;
    final salt = _generateSalt();
    final passwordHash = DatabaseHelper.hashPassword(password, salt);
    final nowStr = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final existing = await txn.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.trim().toLowerCase()],
      );

      if (existing.isNotEmpty) {
        throw Exception('Email already exists');
      }

      final userId = await txn.insert('users', {
        'role': role,
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': nowStr,
        'profile_completed': 0,
      });

      if (role == 'doctor') {
        final doctorId = await txn.insert('doctors', {
          'user_id': userId,
          'specialty': specialty ?? 'General Medicine',
          'room': room ?? 'Room 1',
          'bio': 'Medical doctor dedicated to providing excellent healthcare.',
          'rating': 5.0,
          'years_experience': 1,
          'patients_count': 0,
          'auto_confirm': 1,
        });

        for (int day = 1; day <= 7; day++) {
          final isEnabled = day <= 6 ? 1 : 0;
          final endTime = day == 6 ? '12:00' : '17:00';
          await txn.insert('availability', {
            'doctor_id': doctorId,
            'weekday': day,
            'start_time': '09:00',
            'end_time': endTime,
            'is_enabled': isEnabled,
            'slot_minutes': 30,
          });
        }
      }

      final newUser = User(
        id: userId,
        role: role,
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: passwordHash,
        salt: salt,
        createdAt: nowStr,
        profileCompleted: 0,
      );

      await saveSessionWithTxn(txn, userId, role);
      return newUser;
    });
  }

  Future<void> saveSession(int userId, String role) async {
    final db = await dbHelper.database;
    await db.insert(
      'app_session',
      {'key': 'logged_user_id', 'value': userId.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'app_session',
      {'key': 'logged_user_role', 'value': role},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSessionWithTxn(Transaction txn, int userId, String role) async {
    await txn.insert(
      'app_session',
      {'key': 'logged_user_id', 'value': userId.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await txn.insert(
      'app_session',
      {'key': 'logged_user_role', 'value': role},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> restoreSession() async {
    final db = await dbHelper.database;
    final idRes = await db.query('app_session', where: 'key = ?', whereArgs: ['logged_user_id']);
    final roleRes = await db.query('app_session', where: 'key = ?', whereArgs: ['logged_user_role']);

    if (idRes.isEmpty || roleRes.isEmpty) return null;

    final userId = int.tryParse(idRes.first['value'] as String);
    if (userId == null) return null;

    final userRes = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (userRes.isEmpty) {
      await clearSession();
      return null;
    }

    return User.fromMap(userRes.first);
  }

  Future<void> clearSession() async {
    final db = await dbHelper.database;
    await db.delete('app_session');
  }

  Future<bool> checkEmailExists(String email) async {
    final db = await dbHelper.database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email.trim().toLowerCase()]);
    return res.isNotEmpty;
  }

  Future<void> updateUserProfile(int userId, String fullName, String email) async {
    final db = await dbHelper.database;
    await db.update(
      'users',
      {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
