import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/medical_record_repository.dart';

class MedicalRecordProvider extends ChangeNotifier {
  final MedicalRecordRepository medicalRecordRepository;

  List<MedicalRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  MedicalRecordProvider({MedicalRecordRepository? medicalRecordRepository})
      : medicalRecordRepository = medicalRecordRepository ?? MedicalRecordRepository();

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchMedicalRecords(int patientId, {String? typeFilter}) async {
    _setLoading(true);
    try {
      _records = await medicalRecordRepository.getUserMedicalRecords(patientId, typeFilter: typeFilter);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> addMedicalRecord({
    required int patientId,
    required String title,
    required String type,
    required String filePath,
  }) async {
    _setLoading(true);
    try {
      final rec = await medicalRecordRepository.addMedicalRecord(
        patientId: patientId,
        title: title,
        type: type,
        filePath: filePath,
      );
      _records.insert(0, rec);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (!_disposed) notifyListeners();
  }
}
