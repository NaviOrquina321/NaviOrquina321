import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../data/db/database_helper.dart';

class OnboardingProvider extends ChangeNotifier {
  final DatabaseHelper dbHelper;

  int _patientStep = 1;
  int _doctorStep = 1;
  bool _isLoading = false;
  String? _errorMessage;

  OnboardingProvider({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  int get patientStep => _patientStep;
  int get doctorStep => _doctorStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setPatientStep(int step) {
    _patientStep = step;
    notifyListeners();
  }

  void setDoctorStep(int step) {
    _doctorStep = step;
    notifyListeners();
  }

  Future<void> savePatientDraft(int userId, int step) async {
    final db = await dbHelper.database;
    await db.update('users', {'onboarding_step': step}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> saveDoctorDraft(int userId, int step) async {
    final db = await dbHelper.database;
    await db.update('users', {'onboarding_step': step}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<bool> finishPatientOnboarding({
    required int userId,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> profileData,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        userData['profile_completed'] = 1;
        await txn.update('users', userData, where: 'id = ?', whereArgs: [userId]);

        profileData['user_id'] = userId;
        await txn.insert('patient_profiles', profileData, conflictAlgorithm: ConflictAlgorithm.replace);
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> finishDoctorOnboarding({
    required int userId,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> doctorData,
    required Map<String, dynamic> doctorProfileData,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        userData['profile_completed'] = 1;
        await txn.update('users', userData, where: 'id = ?', whereArgs: [userId]);

        await txn.update('doctors', doctorData, where: 'user_id = ?', whereArgs: [userId]);

        doctorProfileData['user_id'] = userId;
        await txn.insert('doctor_profiles', doctorProfileData, conflictAlgorithm: ConflictAlgorithm.replace);
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
