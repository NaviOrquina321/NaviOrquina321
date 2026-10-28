import '../db/database_helper.dart';
import '../models/models.dart';

class MedicalRecordRepository {
  final DatabaseHelper dbHelper;

  MedicalRecordRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<MedicalRecord>> getUserMedicalRecords(int patientId, {String? typeFilter}) async {
    final db = await dbHelper.database;
    String sql = 'SELECT * FROM medical_records WHERE patient_id = ?';
    List<dynamic> args = [patientId];

    if (typeFilter != null && typeFilter != 'All') {
      sql += ' AND type = ?';
      args.add(typeFilter.toLowerCase());
    }

    sql += ' ORDER BY created_at DESC';

    final results = await db.rawQuery(sql, args);
    return results.map((r) => MedicalRecord.fromMap(r)).toList();
  }

  Future<MedicalRecord> addMedicalRecord({
    required int patientId,
    required String title,
    required String type,
    required String filePath,
  }) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    final id = await db.insert('medical_records', {
      'patient_id': patientId,
      'title': title,
      'type': type.toLowerCase(),
      'file_path': filePath,
      'created_at': nowStr,
    });

    return MedicalRecord(
      id: id,
      patientId: patientId,
      title: title,
      type: type.toLowerCase(),
      filePath: filePath,
      createdAt: nowStr,
    );
  }
}
