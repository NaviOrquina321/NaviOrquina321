import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository settingsRepository;

  UserSettings? _settings;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  SettingsProvider({SettingsRepository? settingsRepository})
      : settingsRepository = settingsRepository ?? SettingsRepository();

  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchSettings(int userId) async {
    _setLoading(true);
    try {
      _settings = await settingsRepository.getUserSettings(userId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> updateSettings(UserSettings updated) async {
    _setLoading(true);
    try {
      await settingsRepository.updateUserSettings(updated);
      _settings = updated;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final success = await settingsRepository.changePassword(userId, oldPassword, newPassword);
      if (!success) {
        _errorMessage = 'Current password is incorrect.';
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAccount(int userId) async {
    _setLoading(true);
    try {
      await settingsRepository.deleteAccount(userId);
      _settings = null;
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
