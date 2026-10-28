import '../db/database_helper.dart';
import '../models/models.dart';

class ChatRepository {
  final DatabaseHelper dbHelper;

  ChatRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<ChatMessage>> getAppointmentMessages(int appointmentId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'messages',
      where: 'appointment_id = ?',
      whereArgs: [appointmentId],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<ChatMessage?> sendMessage({
    required int appointmentId,
    required int senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    final id = await db.insert('messages', {
      'appointment_id': appointmentId,
      'sender_id': senderId,
      'text': trimmed,
      'created_at': nowStr,
    });

    return ChatMessage(
      id: id,
      appointmentId: appointmentId,
      senderId: senderId,
      text: trimmed,
      createdAt: nowStr,
    );
  }

  Future<String?> getPatientNote({required int doctorId, required int patientId}) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'patient_notes',
      where: 'doctor_id = ? AND patient_id = ?',
      whereArgs: [doctorId, patientId],
    );
    if (results.isEmpty) return null;
    return results.first['note'] as String?;
  }

  Future<void> savePatientNote({
    required int doctorId,
    required int patientId,
    required String note,
  }) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.insert('patient_notes', {
      'doctor_id': doctorId,
      'patient_id': patientId,
      'note': note.trim(),
      'created_at': nowStr,
    });
  }
}
