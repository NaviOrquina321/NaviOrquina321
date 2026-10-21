import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('doctor_appointment.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT CHECK(role IN ('patient','doctor')),
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Doctors table
    await db.execute('''
      CREATE TABLE doctors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        specialty TEXT,
        room TEXT,
        bio TEXT,
        rating REAL DEFAULT 5.0,
        years_experience INTEGER DEFAULT 0,
        patients_count INTEGER DEFAULT 0,
        auto_confirm INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Availability table
    await db.execute('''
      CREATE TABLE availability (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER NOT NULL,
        weekday INTEGER NOT NULL CHECK(weekday BETWEEN 1 AND 7),
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        is_enabled INTEGER NOT NULL,
        slot_minutes INTEGER DEFAULT 30,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id) ON DELETE CASCADE
      )
    ''');

    // Appointments table
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        doctor_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        reason TEXT,
        status TEXT CHECK(status IN ('pending','confirmed','in_progress','completed','cancelled','declined')),
        notes TEXT,
        next_visit TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id) ON DELETE CASCADE
      )
    ''');

    // Partial unique index for double booking prevention
    await db.execute('''
      CREATE UNIQUE INDEX idx_appointments_unique_slot
      ON appointments (doctor_id, date, time)
      WHERE status IN ('pending', 'confirmed', 'in_progress')
    ''');

    await db.execute('CREATE INDEX idx_appointments_patient_date ON appointments (patient_id, date)');
    await db.execute('CREATE INDEX idx_appointments_doctor_date ON appointments (doctor_id, date)');

    // Prescriptions table
    await db.execute('''
      CREATE TABLE prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointment_id INTEGER NOT NULL,
        medicine TEXT NOT NULL,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE CASCADE
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointment_id INTEGER UNIQUE NOT NULL,
        patient_id INTEGER NOT NULL,
        doctor_id INTEGER NOT NULL,
        rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
        tags TEXT,
        comment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE CASCADE,
        FOREIGN KEY (patient_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id) ON DELETE CASCADE
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_notifications_user_read ON notifications (user_id, is_read)');

    // App Session table
    await db.execute('''
      CREATE TABLE app_session (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed Data
    await _seedDatabase(db);
  }

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  Future<void> _seedDatabase(Database db) async {
    final nowStr = DateTime.now().toIso8601String();
    const salt = 'fixed_seed_salt';

    // Seed Patient Louie Duarte
    final louieId = await db.insert('users', {
      'role': 'patient',
      'full_name': 'Louie Duarte',
      'email': 'louie@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'created_at': nowStr,
    });

    // Seed Extra Patients
    final markId = await db.insert('users', {
      'role': 'patient',
      'full_name': 'Mark Tan',
      'email': 'mark@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'created_at': nowStr,
    });

    final lizaId = await db.insert('users', {
      'role': 'patient',
      'full_name': 'Liza Ramos',
      'email': 'liza@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'created_at': nowStr,
    });

    final benId = await db.insert('users', {
      'role': 'patient',
      'full_name': 'Ben Cruz',
      'email': 'ben@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'created_at': nowStr,
    });

    // Seed Doctor 1: Dr. Rj Cardinal
    final rjUserId = await db.insert('users', {
      'role': 'doctor',
      'full_name': 'Dr. Rj Cardinal',
      'email': 'rj@clinic.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'created_at': nowStr,
    });

    final rjDocId = await db.insert('doctors', {
      'user_id': rjUserId,
      'specialty': 'Cardiologist',
      'room': 'Room 3',
      'bio': 'Experienced Cardiologist with over 10 years of experience in heart care and surgery.',
      'rating': 4.9,
      'years_experience': 10,
      'patients_count': 120,
      'auto_confirm': 1,
    });

    // Seed Doctor 2: Dr. Ivan Orquina
    final ivanUserId = await db.insert('users', {
      'role': 'doctor',
      'full_name': 'Dr. Ivan Orquina',
      'email': 'ivan@clinic.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'created_at': nowStr,
    });

    final ivanDocId = await db.insert('doctors', {
      'user_id': ivanUserId,
      'specialty': 'Pediatrician',
      'room': 'Room 5',
      'bio': 'Dedicated Pediatrician caring for newborn babies, children, and teenagers.',
      'rating': 4.8,
      'years_experience': 8,
      'patients_count': 95,
      'auto_confirm': 0,
    });

    // Seed Doctor 3: Dr. Alejo
    final alejoUserId = await db.insert('users', {
      'role': 'doctor',
      'full_name': 'Dr. Alejo',
      'email': 'alejo@clinic.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'created_at': nowStr,
    });

    final alejoDocId = await db.insert('doctors', {
      'user_id': alejoUserId,
      'specialty': 'Dermatologist',
      'room': 'Room 2',
      'bio': 'Board certified dermatologist specializing in medical and aesthetic skin care.',
      'rating': 4.7,
      'years_experience': 6,
      'patients_count': 80,
      'auto_confirm': 1,
    });

    // Seed Availability for Doctors (Mon-Fri 09:00-17:00, Sat 09:00-12:00, Sun closed)
    for (final docId in [rjDocId, ivanDocId, alejoDocId]) {
      for (int day = 1; day <= 7; day++) {
        final isEnabled = day <= 6 ? 1 : 0;
        final endTime = day == 6 ? '12:00' : '17:00';
        await db.insert('availability', {
          'doctor_id': docId,
          'weekday': day,
          'start_time': '09:00',
          'end_time': endTime,
          'is_enabled': isEnabled,
          'slot_minutes': 30,
        });
      }
    }

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 3));
    final past = today.subtract(const Duration(days: 5));

    final dateFmt = DateFormat('yyyy-MM-dd');

    // Appointment 1: Confirmed with Dr. Rj Cardinal tomorrow 09:30 AM
    await db.insert('appointments', {
      'patient_id': louieId,
      'doctor_id': rjDocId,
      'date': dateFmt.format(tomorrow),
      'time': '09:30',
      'reason': 'Chest pain follow-up',
      'status': 'confirmed',
      'notes': null,
      'next_visit': null,
      'created_at': nowStr,
    });

    // Appointment 2: Pending with Dr. Ivan Orquina
    await db.insert('appointments', {
      'patient_id': louieId,
      'doctor_id': ivanDocId,
      'date': dateFmt.format(nextWeek),
      'time': '10:00',
      'reason': 'General Health Checkup',
      'status': 'pending',
      'notes': null,
      'next_visit': null,
      'created_at': nowStr,
    });

    // Appointment 3: Confirmed with Dr. Alejo
    await db.insert('appointments', {
      'patient_id': louieId,
      'doctor_id': alejoDocId,
      'date': dateFmt.format(nextWeek),
      'time': '14:00',
      'reason': 'Skin Rash Consultation',
      'status': 'confirmed',
      'notes': null,
      'next_visit': null,
      'created_at': nowStr,
    });

    // Appointment 4: Completed past visit with Dr. Ivan Orquina
    await db.insert('appointments', {
      'patient_id': louieId,
      'doctor_id': ivanDocId,
      'date': dateFmt.format(past),
      'time': '11:00',
      'reason': 'Routine pediatric check',
      'status': 'completed',
      'notes': 'Patient is healthy and up to date with vaccines.',
      'next_visit': '1 month',
      'created_at': nowStr,
    });

    // Doctor visits for Dr. Rj Cardinal
    await db.insert('appointments', {
      'patient_id': markId,
      'doctor_id': rjDocId,
      'date': dateFmt.format(today),
      'time': '09:00',
      'reason': 'Hypertension consultation',
      'status': 'confirmed',
      'notes': null,
      'next_visit': null,
      'created_at': nowStr,
    });

    await db.insert('appointments', {
      'patient_id': lizaId,
      'doctor_id': rjDocId,
      'date': dateFmt.format(today),
      'time': '10:30',
      'reason': 'ECG review',
      'status': 'pending',
      'notes': null,
      'next_visit': null,
      'created_at': nowStr,
    });

    await db.insert('appointments', {
      'patient_id': benId,
      'doctor_id': rjDocId,
      'date': dateFmt.format(today),
      'time': '11:30',
      'reason': 'Heart rate fluctuations',
      'status': 'confirmed',
      'notes': null,
      'next_visit': null,
      'created_at': nowStr,
    });

    // Notifications for Louie
    await db.insert('notifications', {
      'user_id': louieId,
      'type': 'visit_reminder',
      'title': 'Upcoming Visit Tomorrow',
      'body': 'You have an appointment with Dr. Rj Cardinal tomorrow at 9:30 AM.',
      'is_read': 0,
      'created_at': nowStr,
    });

    await db.insert('notifications', {
      'user_id': louieId,
      'type': 'request_accepted',
      'title': 'Appointment Request Confirmed',
      'body': 'Dr. Rj Cardinal has confirmed your appointment request.',
      'is_read': 0,
      'created_at': nowStr,
    });

    await db.insert('notifications', {
      'user_id': louieId,
      'type': 'rate_visit',
      'title': 'Rate Your Recent Visit',
      'body': 'Please rate your past visit with Dr. Ivan Orquina.',
      'is_read': 1,
      'created_at': nowStr,
    });
  }
}
