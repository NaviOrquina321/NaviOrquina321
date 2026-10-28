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
      version: 5,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        first_name TEXT,
        middle_name TEXT,
        last_name TEXT,
        suffix TEXT,
        birth_date TEXT,
        sex TEXT,
        civil_status TEXT,
        phone TEXT,
        house_street TEXT,
        barangay TEXT,
        city TEXT,
        province TEXT,
        zip TEXT,
        latitude REAL,
        longitude REAL,
        photo_path TEXT,
        profile_completed INTEGER DEFAULT 0,
        onboarding_step INTEGER DEFAULT 0,
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
        consultation_fee REAL DEFAULT 500.0,
        clinic_name TEXT,
        clinic_address TEXT,
        clinic_phone TEXT,
        directions_note TEXT,
        walk_ins INTEGER DEFAULT 1,
        latitude REAL,
        longitude REAL,
        location_accuracy REAL,
        location_updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Patient Profiles table
    await db.execute('''
      CREATE TABLE patient_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        emergency_name TEXT,
        emergency_relation TEXT,
        emergency_phone TEXT,
        blood_type TEXT,
        height_cm REAL,
        weight_kg REAL,
        allergies TEXT,
        conditions TEXT,
        medications TEXT,
        philhealth_no TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Doctor Profiles table
    await db.execute('''
      CREATE TABLE doctor_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        specialty TEXT,
        sub_specialty TEXT,
        prc_number TEXT,
        license_expiry TEXT,
        years_experience INTEGER DEFAULT 0,
        medical_school TEXT,
        graduation_year INTEGER,
        languages TEXT,
        bio TEXT,
        prc_photo_path TEXT,
        verification_status TEXT DEFAULT 'pending',
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
        visit_type TEXT DEFAULT 'In person',
        payment_method TEXT,
        payment_status TEXT,
        amount REAL DEFAULT 500.0,
        meeting_link TEXT,
        arrived_at TEXT,
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

    // Help & Support tables
    await _createSupportTables(db);

    // Medical Records table
    await db.execute('''
      CREATE TABLE medical_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        user_id INTEGER PRIMARY KEY,
        reminders_on INTEGER DEFAULT 1,
        chat_on INTEGER DEFAULT 1,
        offers_on INTEGER DEFAULT 1,
        remind_before TEXT DEFAULT '1 hour',
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Messages table (appointment chat)
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointment_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE CASCADE
      )
    ''');

    // Patient Notes table (private notes saved by doctor per patient)
    await db.execute('''
      CREATE TABLE patient_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER NOT NULL,
        patient_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(doctor_id, patient_id) ON CONFLICT REPLACE
      )
    ''');

    // Seed Data
    await _seedDatabase(db);
  }

  Future<void> _createSupportTables(Database db) async {
    await db.execute('''
      CREATE TABLE support_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        text TEXT NOT NULL,
        sender TEXT NOT NULL CHECK(sender IN ('user', 'support')),
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE support_tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT DEFAULT 'open',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE faq_feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faq_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        helpful INTEGER NOT NULL,
        UNIQUE(faq_id, user_id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSupportTables(db);
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE appointments ADD COLUMN visit_type TEXT DEFAULT 'In person'");
      await db.execute("ALTER TABLE appointments ADD COLUMN payment_method TEXT");
      await db.execute("ALTER TABLE appointments ADD COLUMN payment_status TEXT");
      await db.execute("ALTER TABLE appointments ADD COLUMN amount REAL DEFAULT 500.0");
      await db.execute("ALTER TABLE appointments ADD COLUMN meeting_link TEXT");
      await db.execute("ALTER TABLE doctors ADD COLUMN consultation_fee REAL DEFAULT 500.0");

      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patient_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          file_path TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (patient_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          user_id INTEGER PRIMARY KEY,
          reminders_on INTEGER DEFAULT 1,
          chat_on INTEGER DEFAULT 1,
          offers_on INTEGER DEFAULT 1,
          remind_before TEXT DEFAULT '1 hour',
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          appointment_id INTEGER NOT NULL,
          sender_id INTEGER NOT NULL,
          text TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS patient_notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_id INTEGER NOT NULL,
          patient_id INTEGER NOT NULL,
          note TEXT NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE(doctor_id, patient_id) ON CONFLICT REPLACE
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE users ADD COLUMN first_name TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN middle_name TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN last_name TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN suffix TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN birth_date TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN sex TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN civil_status TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN phone TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN house_street TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN barangay TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN city TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN province TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN zip TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN latitude REAL");
      await db.execute("ALTER TABLE users ADD COLUMN longitude REAL");
      await db.execute("ALTER TABLE users ADD COLUMN photo_path TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN profile_completed INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE users ADD COLUMN onboarding_step INTEGER DEFAULT 0");

      await db.execute("UPDATE users SET profile_completed = 1");

      await db.execute('''
        CREATE TABLE IF NOT EXISTS patient_profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          emergency_name TEXT,
          emergency_relation TEXT,
          emergency_phone TEXT,
          blood_type TEXT,
          height_cm REAL,
          weight_kg REAL,
          allergies TEXT,
          conditions TEXT,
          medications TEXT,
          philhealth_no TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS doctor_profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          specialty TEXT,
          sub_specialty TEXT,
          prc_number TEXT,
          license_expiry TEXT,
          years_experience INTEGER DEFAULT 0,
          medical_school TEXT,
          graduation_year INTEGER,
          languages TEXT,
          bio TEXT,
          prc_photo_path TEXT,
          verification_status TEXT DEFAULT 'pending',
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute("ALTER TABLE doctors ADD COLUMN clinic_name TEXT");
      await db.execute("ALTER TABLE doctors ADD COLUMN clinic_address TEXT");
      await db.execute("ALTER TABLE doctors ADD COLUMN clinic_phone TEXT");
      await db.execute("ALTER TABLE doctors ADD COLUMN directions_note TEXT");
      await db.execute("ALTER TABLE doctors ADD COLUMN walk_ins INTEGER DEFAULT 1");
      await db.execute("ALTER TABLE doctors ADD COLUMN latitude REAL");
      await db.execute("ALTER TABLE doctors ADD COLUMN longitude REAL");
      await db.execute("ALTER TABLE doctors ADD COLUMN location_accuracy REAL");
      await db.execute("ALTER TABLE doctors ADD COLUMN location_updated_at TEXT");

      await db.execute("ALTER TABLE appointments ADD COLUMN arrived_at TEXT");
    }
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
      'first_name': 'Louie',
      'last_name': 'Duarte',
      'email': 'louie@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'profile_completed': 1,
      'created_at': nowStr,
    });

    await db.insert('patient_profiles', {
      'user_id': louieId,
      'blood_type': 'O+',
      'allergies': 'Penicillin, Peanuts',
      'conditions': 'Hypertension',
      'emergency_name': 'Maria Duarte',
      'emergency_relation': 'Spouse',
      'emergency_phone': '09171234567',
    });

    // Seed Extra Patients
    final markId = await db.insert('users', {
      'role': 'patient',
      'full_name': 'Mark Tan',
      'first_name': 'Mark',
      'last_name': 'Tan',
      'email': 'mark@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'profile_completed': 1,
      'created_at': nowStr,
    });

    final lizaId = await db.insert('users', {
      'role': 'patient',
      'full_name': 'Liza Ramos',
      'first_name': 'Liza',
      'last_name': 'Ramos',
      'email': 'liza@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'profile_completed': 1,
      'created_at': nowStr,
    });

    final benId = await db.insert('users', {
      'role': 'patient',
      'full_name': 'Ben Cruz',
      'first_name': 'Ben',
      'last_name': 'Cruz',
      'email': 'ben@email.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'profile_completed': 1,
      'created_at': nowStr,
    });

    // Seed Doctor 1: Dr. Rj Cardinal
    final rjUserId = await db.insert('users', {
      'role': 'doctor',
      'full_name': 'Dr. Rj Cardinal',
      'first_name': 'Rj',
      'last_name': 'Cardinal',
      'suffix': 'MD',
      'email': 'rj@clinic.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'profile_completed': 1,
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
      'clinic_name': 'Central Health Clinic',
      'clinic_address': '123 Medical Center Way, Suite 400, Healthcare District, Metro Manila',
      'clinic_phone': '+63 2 8123 4567',
      'directions_note': 'Near St. Luke Hospital, 4th Floor',
      'latitude': 14.5995,
      'longitude': 120.9842,
      'location_accuracy': 10.0,
      'location_updated_at': nowStr,
    });

    // Seed Doctor 2: Dr. Ivan Orquina
    final ivanUserId = await db.insert('users', {
      'role': 'doctor',
      'full_name': 'Dr. Ivan Orquina',
      'first_name': 'Ivan',
      'last_name': 'Orquina',
      'suffix': 'MD',
      'email': 'ivan@clinic.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'profile_completed': 1,
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
      'clinic_name': 'Children Care Clinic',
      'clinic_address': '456 Pediatric Way, Suite 101, Metro Manila',
      'clinic_phone': '+63 2 8234 5678',
      'latitude': 14.5900,
      'longitude': 120.9800,
      'location_accuracy': 12.0,
      'location_updated_at': nowStr,
    });

    // Seed Doctor 3: Dr. Alejo
    final alejoUserId = await db.insert('users', {
      'role': 'doctor',
      'full_name': 'Dr. Alejo',
      'first_name': 'Alejo',
      'last_name': 'Santos',
      'suffix': 'MD',
      'email': 'alejo@clinic.com',
      'password_hash': hashPassword('Password123', salt),
      'salt': salt,
      'profile_completed': 1,
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
      'clinic_name': 'Aesthetic Skin Clinic',
      'clinic_address': '789 Skin Care Blvd, Metro Manila',
      'clinic_phone': '+63 2 8345 6789',
      'latitude': 14.6050,
      'longitude': 120.9900,
      'location_accuracy': 15.0,
      'location_updated_at': nowStr,
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
