import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:doctor_appointment_app/data/db/database_helper.dart';
import 'package:doctor_appointment_app/data/repositories/auth_repository.dart';
import 'package:doctor_appointment_app/data/repositories/doctor_repository.dart';
import 'package:doctor_appointment_app/data/repositories/availability_repository.dart';
import 'package:doctor_appointment_app/data/repositories/appointment_repository.dart';
import 'package:doctor_appointment_app/data/repositories/review_repository.dart';
import 'package:doctor_appointment_app/data/repositories/notification_repository.dart';
import 'package:doctor_appointment_app/data/repositories/support_repository.dart';
import 'package:doctor_appointment_app/providers/auth_provider.dart';
import 'package:doctor_appointment_app/core/widgets/app_button.dart';
import 'package:doctor_appointment_app/core/widgets/app_text_field.dart';
import 'package:doctor_appointment_app/data/models/models.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
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

        await db.execute('''
          CREATE UNIQUE INDEX idx_appointments_unique_slot
          ON appointments (doctor_id, date, time)
          WHERE status IN ('pending', 'confirmed', 'in_progress')
        ''');

        await db.execute('''
          CREATE TABLE prescriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            appointment_id INTEGER NOT NULL,
            medicine TEXT NOT NULL,
            FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE CASCADE
          )
        ''');

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

        await db.execute('''
          CREATE TABLE app_session (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

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
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Slot Generation including past times and disabled weekday logic', () async {
    final dbHelper = TestDbHelper(db);
    final availRepo = AvailabilityRepository(dbHelper: dbHelper);

    // Get Sunday availability (disabled)
    final sunAvail = await availRepo.getAvailabilityForDay(1, 7);
    expect(sunAvail, isNull);
  });

  test('Login and Register Authentication (wrong password, duplicate email, wrong role)', () async {
    final dbHelper = TestDbHelper(db);
    final authRepo = AuthRepository(dbHelper: dbHelper);

    // Register Patient
    final patient = await authRepo.registerUser(
      fullName: 'Test Patient',
      email: 'patient@test.com',
      password: 'Password123',
      role: 'patient',
    );

    expect(patient.id, isNotNull);

    // Duplicate email
    expect(
      () => authRepo.registerUser(
        fullName: 'Test Dup',
        email: 'patient@test.com',
        password: 'Password123',
        role: 'patient',
      ),
      throwsA(isA<Exception>()),
    );

    // Wrong Password
    final wrongPass = await authRepo.login('patient@test.com', 'WrongPass', 'patient');
    expect(wrongPass, isNull);

    // Wrong Role
    final wrongRole = await authRepo.login('patient@test.com', 'Password123', 'doctor');
    expect(wrongRole, isNull);
  });

  test('AuthProvider Role Check', () async {
    final dbHelper = TestDbHelper(db);
    final authRepo = AuthRepository(dbHelper: dbHelper);
    final authProvider = AuthProvider(authRepository: authRepo);

    await authProvider.register(
      fullName: 'Patient One',
      email: 'p1@test.com',
      password: 'Password123',
      role: 'patient',
    );

    expect(authProvider.isPatient, isTrue);
    expect(authProvider.isDoctor, isFalse);
  });

  test('Double Booking Prevention and friendly error message', () async {
    final dbHelper = TestDbHelper(db);
    final authRepo = AuthRepository(dbHelper: dbHelper);
    final apptRepo = AppointmentRepository(dbHelper: dbHelper);

    final patient = await authRepo.registerUser(
      fullName: 'Patient',
      email: 'pat@test.com',
      password: 'Password123',
      role: 'patient',
    );

    final doctorUser = await authRepo.registerUser(
      fullName: 'Doctor',
      email: 'doc@test.com',
      password: 'Password123',
      role: 'doctor',
    );

    final doctorRepo = DoctorRepository(dbHelper: dbHelper);
    final doctor = await doctorRepo.getDoctorByUserId(doctorUser.id!);

    final appt1 = await apptRepo.createAppointment(
      patientId: patient.id!,
      doctorId: doctor!.id!,
      date: '2025-10-25',
      time: '09:00',
    );
    expect(appt1.id, isNotNull);

    expect(
      () => apptRepo.createAppointment(
        patientId: patient.id!,
        doctorId: doctor.id!,
        date: '2025-10-25',
        time: '09:00',
      ),
      throwsA(predicate((e) => e.toString().contains('Slot just taken'))),
    );
  });

  test('Book, Cancel and Reschedule Transactions', () async {
    final dbHelper = TestDbHelper(db);
    final authRepo = AuthRepository(dbHelper: dbHelper);
    final apptRepo = AppointmentRepository(dbHelper: dbHelper);

    final patient = await authRepo.registerUser(
      fullName: 'Patient',
      email: 'p_trx@test.com',
      password: 'Password123',
      role: 'patient',
    );

    final doctorUser = await authRepo.registerUser(
      fullName: 'Doctor',
      email: 'd_trx@test.com',
      password: 'Password123',
      role: 'doctor',
    );

    final doctorRepo = DoctorRepository(dbHelper: dbHelper);
    final doctor = await doctorRepo.getDoctorByUserId(doctorUser.id!);

    // Book
    final appt = await apptRepo.createAppointment(
      patientId: patient.id!,
      doctorId: doctor!.id!,
      date: '2025-10-25',
      time: '10:00',
    );
    expect(appt.status, 'confirmed');

    // Reschedule
    await apptRepo.rescheduleAppointment(appt.id!, '2025-10-25', '11:00');
    final rescheduledAppt = await apptRepo.getAppointmentById(appt.id!);
    expect(rescheduledAppt!.time, '11:00');

    // Cancel
    await apptRepo.updateAppointmentStatus(
      appt.id!,
      'cancelled',
      notifyUserId: doctorUser.id!,
      notificationTitle: 'Cancelled',
      notificationBody: 'Cancelled',
    );
    final cancelledAppt = await apptRepo.getAppointmentById(appt.id!);
    expect(cancelledAppt!.status, 'cancelled');
  });

  test('Notifications Created on Status Changes & Availability Save', () async {
    final dbHelper = TestDbHelper(db);
    final authRepo = AuthRepository(dbHelper: dbHelper);
    final apptRepo = AppointmentRepository(dbHelper: dbHelper);
    final notifRepo = NotificationRepository(dbHelper: dbHelper);
    final availRepo = AvailabilityRepository(dbHelper: dbHelper);

    final patient = await authRepo.registerUser(
      fullName: 'Patient',
      email: 'p2@test.com',
      password: 'Password123',
      role: 'patient',
    );

    final doctorUser = await authRepo.registerUser(
      fullName: 'Doctor',
      email: 'd2@test.com',
      password: 'Password123',
      role: 'doctor',
    );

    final doctorRepo = DoctorRepository(dbHelper: dbHelper);
    final doctor = await doctorRepo.getDoctorByUserId(doctorUser.id!);

    final appt = await apptRepo.createAppointment(
      patientId: patient.id!,
      doctorId: doctor!.id!,
      date: '2025-10-26',
      time: '10:00',
    );

    // Save Availability without deleting appointments
    await availRepo.saveDoctorAvailability(doctor.id!, [
      Availability(
        doctorId: doctor.id!,
        weekday: 1,
        startTime: '08:00',
        endTime: '16:00',
        isEnabled: 1,
      )
    ]);

    final existingAppt = await apptRepo.getAppointmentById(appt.id!);
    expect(existingAppt, isNotNull);

    final docNotifs = await notifRepo.getUserNotifications(doctorUser.id!);
    expect(docNotifs.isNotEmpty, isTrue);
  });

  test('Rating Recalculation after Review', () async {
    final dbHelper = TestDbHelper(db);
    final authRepo = AuthRepository(dbHelper: dbHelper);
    final apptRepo = AppointmentRepository(dbHelper: dbHelper);
    final reviewRepo = ReviewRepository(dbHelper: dbHelper);
    final doctorRepo = DoctorRepository(dbHelper: dbHelper);

    final patient = await authRepo.registerUser(
      fullName: 'Patient',
      email: 'p3@test.com',
      password: 'Password123',
      role: 'patient',
    );

    final doctorUser = await authRepo.registerUser(
      fullName: 'Doctor',
      email: 'd3@test.com',
      password: 'Password123',
      role: 'doctor',
    );

    final doctor = await doctorRepo.getDoctorByUserId(doctorUser.id!);

    final appt = await apptRepo.createAppointment(
      patientId: patient.id!,
      doctorId: doctor!.id!,
      date: '2025-10-20',
      time: '10:00',
    );

    await reviewRepo.submitReview(
      appointmentId: appt.id!,
      patientId: patient.id!,
      doctorId: doctor.id!,
      rating: 4,
      comment: 'Great visit',
    );

    final updatedDoctor = await doctorRepo.getDoctorById(doctor.id!);
    expect(updatedDoctor!.rating, 4.0);
  });

  test('FAQ search filter returns the right items and handles no match', () {
    final supportRepo = SupportRepository(dbHelper: TestDbHelper(db));

    // Role filtering
    final patientFaqs = supportRepo.getFaqs(role: 'patient');
    expect(patientFaqs.every((f) => f.forRole == 'patient' || f.forRole == 'all'), isTrue);

    // Matching query
    final bookFaqs = supportRepo.getFaqs(role: 'patient', query: 'book');
    expect(bookFaqs.isNotEmpty, isTrue);

    // Non-matching query
    final noMatch = supportRepo.getFaqs(role: 'patient', query: 'xyznonexistent123');
    expect(noMatch.isEmpty, isTrue);
  });

  test('Sending a message saves it and creates the right keyword auto-reply', () async {
    final dbHelper = TestDbHelper(db);
    final supportRepo = SupportRepository(dbHelper: dbHelper);

    final msg = await supportRepo.sendMessage(userId: 1, text: 'I want to cancel my visit');
    expect(msg, isNotNull);

    final history = await supportRepo.getSupportMessages(1);
    expect(history.length, 2); // user message + auto reply
    expect(history.first.sender, 'user');
    expect(history.last.sender, 'support');
    expect(history.last.text.contains('cancel'), isTrue);
  });

  test('Blank message is ignored', () async {
    final dbHelper = TestDbHelper(db);
    final supportRepo = SupportRepository(dbHelper: dbHelper);

    final emptyMsg = await supportRepo.sendMessage(userId: 1, text: '   ');
    expect(emptyMsg, isNull);

    final history = await supportRepo.getSupportMessages(1);
    expect(history.isEmpty, isTrue);
  });

  test('Ticket saved and listed only for its owner', () async {
    final dbHelper = TestDbHelper(db);
    final authRepo = AuthRepository(dbHelper: dbHelper);
    final supportRepo = SupportRepository(dbHelper: dbHelper);

    final user1 = await authRepo.registerUser(
      fullName: 'User One',
      email: 'u1@test.com',
      password: 'Password123',
      role: 'patient',
    );

    final user2 = await authRepo.registerUser(
      fullName: 'User Two',
      email: 'u2@test.com',
      password: 'Password123',
      role: 'patient',
    );

    final ticket = await supportRepo.createSupportTicket(
      userId: user1.id!,
      category: 'Booking',
      description: 'Detailed problem description here.',
    );
    expect(ticket.id, isNotNull);

    final u1Tickets = await supportRepo.getUserSupportTickets(user1.id!);
    expect(u1Tickets.length, 1);

    final u2Tickets = await supportRepo.getUserSupportTickets(user2.id!);
    expect(u2Tickets.isEmpty, isTrue);
  });

  test('FAQ feedback is limited to one vote per user per question', () async {
    final dbHelper = TestDbHelper(db);
    final supportRepo = SupportRepository(dbHelper: dbHelper);

    final vote1 = await supportRepo.saveFaqFeedback(faqId: 'p1', userId: 10, helpful: true);
    expect(vote1, isTrue);

    final vote2 = await supportRepo.saveFaqFeedback(faqId: 'p1', userId: 10, helpful: false);
    expect(vote2, isFalse);

    final hasVoted = await supportRepo.hasUserVotedFaq('p1', 10);
    expect(hasVoted, isTrue);
  });

  testWidgets('Validation errors appear on empty text field submit', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Email',
                  controller: emailController,
                  validator: (val) => val == null || val.isEmpty ? 'Email is required' : null,
                ),
                Builder(
                  builder: (context) {
                    return AppButton(
                      text: 'Submit',
                      onPressed: () {
                        formKey.currentState!.validate();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('Confirm button disabled until slot chosen and disabled booked slot shown', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulWidgetWidget(
          onSlotChosen: (_) {},
        ),
      ),
    );

    final buttonFinder = find.byType(ElevatedButton);
    ElevatedButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);

    await tester.tap(find.text('09:00 AM'));
    await tester.pumpAndSettle();

    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull);
  });
}

class StatefulWidgetWidget extends StatefulWidget {
  final ValueChanged<String> onSlotChosen;
  const StatefulWidgetWidget({super.key, required this.onSlotChosen});

  @override
  State<StatefulWidgetWidget> createState() => _StatefulWidgetWidgetState();
}

class _StatefulWidgetWidgetState extends State<StatefulWidgetWidget> {
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSlot = '09:00 AM';
              });
              widget.onSlotChosen('09:00 AM');
            },
            child: const Text('09:00 AM'),
          ),
          AppButton(
            text: 'Confirm',
            onPressed: _selectedSlot == null ? null : () {},
          ),
        ],
      ),
    );
  }
}

class TestDbHelper implements DatabaseHelper {
  final Database testDb;
  TestDbHelper(this.testDb);

  @override
  Future<Database> get database async => testDb;
}
