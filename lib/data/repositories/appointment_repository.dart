import '../db/database_helper.dart';
import '../models/models.dart';

class AppointmentRepository {
  final DatabaseHelper dbHelper;

  AppointmentRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Appointment> createAppointment({
    required int patientId,
    required int doctorId,
    required String date, // 'yyyy-MM-dd'
    required String time, // 'HH:mm'
    String? reason,
    String visitType = 'In person',
  }) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final docRes = await txn.query('doctors', where: 'id = ?', whereArgs: [doctorId]);
      if (docRes.isEmpty) throw Exception('Doctor not found');

      final doctorMap = docRes.first;
      final autoConfirm = (doctorMap['auto_confirm'] as int?) ?? 1;
      final status = autoConfirm == 1 ? 'confirmed' : 'pending';

      try {
        final doctorFee = (doctorMap['consultation_fee'] as num?)?.toDouble() ?? 500.0;

        final id = await txn.insert('appointments', {
          'patient_id': patientId,
          'doctor_id': doctorId,
          'date': date,
          'time': time,
          'reason': reason,
          'status': status,
          'created_at': nowStr,
          'visit_type': visitType,
          'amount': doctorFee,
        });

        final patientRes = await txn.query('users', where: 'id = ?', whereArgs: [patientId]);
        final patientName = patientRes.isNotEmpty ? (patientRes.first['full_name'] as String) : 'Patient';

        final docUserRes = await txn.query('users', where: 'id = ?', whereArgs: [doctorMap['user_id']]);
        final doctorName = docUserRes.isNotEmpty ? (docUserRes.first['full_name'] as String) : 'Doctor';

        final notificationTitle = status == 'confirmed' ? 'Appointment Confirmed' : 'New Appointment Request';
        final notificationBodyPatient = status == 'confirmed'
            ? 'Your appointment with $doctorName on $date at $time has been confirmed.'
            : 'Your appointment request with $doctorName is pending approval.';

        await txn.insert('notifications', {
          'user_id': patientId,
          'type': 'appointment_created',
          'title': notificationTitle,
          'body': notificationBodyPatient,
          'is_read': 0,
          'created_at': nowStr,
        });

        await txn.insert('notifications', {
          'user_id': doctorMap['user_id'],
          'type': 'appointment_created',
          'title': 'New Appointment Request',
          'body': '$patientName requested an appointment on $date at $time.',
          'is_read': 0,
          'created_at': nowStr,
        });

        return Appointment(
          id: id,
          patientId: patientId,
          doctorId: doctorId,
          date: date,
          time: time,
          reason: reason,
          status: status,
          createdAt: nowStr,
          visitType: visitType,
          amount: doctorFee,
        );
      } catch (e) {
        if (e.toString().contains('UNIQUE constraint failed')) {
          throw Exception('Slot just taken. Please choose another time slot.');
        }
        rethrow;
      }
    });
  }

  Future<List<Appointment>> getPatientAppointments(int patientId, {bool past = false, String? dateFilter}) async {
    final db = await dbHelper.database;
    String sql = '''
      SELECT a.*, d.specialty, d.room, d.rating, d.user_id as doc_user_id,
             u.full_name as doc_name, u.email as doc_email
      FROM appointments a
      JOIN doctors d ON a.doctor_id = d.id
      JOIN users u ON d.user_id = u.id
      WHERE a.patient_id = ? AND ${past ? "a.status IN ('completed', 'cancelled', 'declined')" : "a.status IN ('pending', 'confirmed', 'in_progress')"}
    ''';

    List<dynamic> args = [patientId];

    if (dateFilter != null) {
      sql += ' AND a.date = ?';
      args.add(dateFilter);
    }

    sql += ' ORDER BY a.date DESC, a.time DESC';

    final results = await db.rawQuery(sql, args);

    return results.map((row) {
      final docUser = User(
        id: row['doc_user_id'] as int,
        role: 'doctor',
        fullName: row['doc_name'] as String,
        email: row['doc_email'] as String,
        passwordHash: '',
        salt: '',
        createdAt: '',
      );
      final doctor = Doctor(
        id: row['doctor_id'] as int,
        userId: row['doc_user_id'] as int,
        specialty: row['specialty'] as String?,
        room: row['room'] as String?,
        rating: (row['rating'] as num).toDouble(),
        user: docUser,
      );
      return Appointment.fromMap(row, doctor: doctor);
    }).toList();
  }

  Future<List<Appointment>> getDoctorAppointments(int doctorId, {String? dateFilter, String? filterType}) async {
    final db = await dbHelper.database;
    String sql = '''
      SELECT a.*, u.full_name as patient_name, u.email as patient_email, u.created_at as patient_created_at
      FROM appointments a
      JOIN users u ON a.patient_id = u.id
      WHERE a.doctor_id = ?
    ''';

    List<dynamic> args = [doctorId];

    if (dateFilter != null) {
      sql += ' AND a.date = ?';
      args.add(dateFilter);
    }

    if (filterType == 'Follow-up') {
      sql += " AND a.reason LIKE '%follow%'";
    }

    sql += ' ORDER BY a.date ASC, a.time ASC';

    final results = await db.rawQuery(sql, args);

    return results.map((row) {
      final patientUser = User(
        id: row['patient_id'] as int,
        role: 'patient',
        fullName: row['patient_name'] as String,
        email: row['patient_email'] as String,
        passwordHash: '',
        salt: '',
        createdAt: row['patient_created_at'] as String,
      );
      return Appointment.fromMap(row, patientUser: patientUser);
    }).toList();
  }

  Future<Appointment?> getAppointmentById(int appointmentId) async {
    final db = await dbHelper.database;
    final results = await db.rawQuery('''
      SELECT a.*, d.specialty, d.room, d.rating, d.user_id as doc_user_id,
             u_doc.full_name as doc_name, u_doc.email as doc_email,
             u_pat.full_name as patient_name, u_pat.email as patient_email
      FROM appointments a
      JOIN doctors d ON a.doctor_id = d.id
      JOIN users u_doc ON d.user_id = u_doc.id
      JOIN users u_pat ON a.patient_id = u_pat.id
      WHERE a.id = ?
    ''', [appointmentId]);

    if (results.isEmpty) return null;

    final row = results.first;

    final docUser = User(
      id: row['doc_user_id'] as int,
      role: 'doctor',
      fullName: row['doc_name'] as String,
      email: row['doc_email'] as String,
      passwordHash: '',
      salt: '',
      createdAt: '',
    );

    final doctor = Doctor(
      id: row['doctor_id'] as int,
      userId: row['doc_user_id'] as int,
      specialty: row['specialty'] as String?,
      room: row['room'] as String?,
      rating: (row['rating'] as num).toDouble(),
      user: docUser,
    );

    final patientUser = User(
      id: row['patient_id'] as int,
      role: 'patient',
      fullName: row['patient_name'] as String,
      email: row['patient_email'] as String,
      passwordHash: '',
      salt: '',
      createdAt: '',
    );

    return Appointment.fromMap(row, patientUser: patientUser, doctor: doctor);
  }

  Future<void> markArrived({
    required int appointmentId,
    required String arrivedAt,
    required int doctorUserId,
    required String patientName,
  }) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'appointments',
        {'arrived_at': arrivedAt},
        where: 'id = ?',
        whereArgs: [appointmentId],
      );

      await txn.insert('notifications', {
        'user_id': doctorUserId,
        'type': 'patient_arrived',
        'title': 'Patient Arrived',
        'body': '$patientName has arrived at the clinic.',
        'is_read': 0,
        'created_at': nowStr,
      });
    });
  }

  Future<void> updateAppointmentStatus(int appointmentId, String newStatus, {required int notifyUserId, required String notificationTitle, required String notificationBody}) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'appointments',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [appointmentId],
      );

      await txn.insert('notifications', {
        'user_id': notifyUserId,
        'type': 'status_change',
        'title': notificationTitle,
        'body': notificationBody,
        'is_read': 0,
        'created_at': nowStr,
      });
    });
  }

  Future<void> rescheduleAppointment(int appointmentId, String newDate, String newTime) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final apptRes = await txn.query('appointments', where: 'id = ?', whereArgs: [appointmentId]);
      if (apptRes.isEmpty) throw Exception('Appointment not found');

      final appt = apptRes.first;
      final docId = appt['doctor_id'] as int;

      try {
        await txn.update(
          'appointments',
          {'date': newDate, 'time': newTime, 'status': 'confirmed'},
          where: 'id = ?',
          whereArgs: [appointmentId],
        );

        final docRes = await txn.query('doctors', where: 'id = ?', whereArgs: [docId]);
        final docUserId = docRes.first['user_id'] as int;

        await txn.insert('notifications', {
          'user_id': docUserId,
          'type': 'rescheduled',
          'title': 'Appointment Rescheduled',
          'body': 'Appointment #$appointmentId was rescheduled to $newDate at $newTime.',
          'is_read': 0,
          'created_at': nowStr,
        });
      } catch (e) {
        if (e.toString().contains('UNIQUE constraint failed')) {
          throw Exception('Slot just taken. Please choose another time slot.');
        }
        rethrow;
      }
    });
  }

  Future<void> completeConsultation({
    required int appointmentId,
    required String notes,
    required List<String> medicines,
    String? nextVisit,
  }) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final apptRes = await txn.query('appointments', where: 'id = ?', whereArgs: [appointmentId]);
      if (apptRes.isEmpty) throw Exception('Appointment not found');

      final appt = apptRes.first;
      final patientId = appt['patient_id'] as int;

      await txn.update(
        'appointments',
        {
          'status': 'completed',
          'notes': notes,
          'next_visit': nextVisit,
        },
        where: 'id = ?',
        whereArgs: [appointmentId],
      );

      for (final med in medicines) {
        if (med.trim().isNotEmpty) {
          await txn.insert('prescriptions', {
            'appointment_id': appointmentId,
            'medicine': med.trim(),
          });
        }
      }

      await txn.insert('notifications', {
        'user_id': patientId,
        'type': 'rate_visit',
        'title': 'Visit Completed',
        'body': 'Your visit is complete. Please rate your experience!',
        'is_read': 0,
        'created_at': nowStr,
      });
    });
  }

  Future<List<Prescription>> getPrescriptionsForAppointment(int appointmentId) async {
    final db = await dbHelper.database;
    final results = await db.query('prescriptions', where: 'appointment_id = ?', whereArgs: [appointmentId]);
    return results.map((r) => Prescription.fromMap(r)).toList();
  }

  Future<void> savePaymentInfo(int appointmentId, String paymentMethod, String paymentStatus, double amount) async {
    final db = await dbHelper.database;
    await db.update(
      'appointments',
      {
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'amount': amount,
      },
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  Future<void> saveMeetingLink(int appointmentId, String meetingLink) async {
    final db = await dbHelper.database;
    await db.update(
      'appointments',
      {'meeting_link': meetingLink},
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  Future<List<String>> getBookedSlotsForDoctorAndDate(int doctorId, String date) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'appointments',
      columns: ['time'],
      where: "doctor_id = ? AND date = ? AND status IN ('pending', 'confirmed', 'in_progress')",
      whereArgs: [doctorId, date],
    );
    return results.map((r) => r['time'] as String).toList();
  }
}
