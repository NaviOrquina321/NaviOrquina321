import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  AuthProvider({AuthRepository? authRepository})
      : authRepository = authRepository ?? AuthRepository();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isDoctor => _currentUser?.role == 'doctor';
  bool get isPatient => _currentUser?.role == 'patient';

  Future<void> refreshCurrentUser() async {
    if (_currentUser?.id != null) {
      final updated = await authRepository.getUserById(_currentUser!.id!);
      if (updated != null) {
        _currentUser = updated;
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<bool> updatePhoto(String? localSourcePath) async {
    if (_currentUser?.id == null) return false;
    _setLoading(true);
    try {
      await authRepository.updateProfilePhoto(_currentUser!.id!, localSourcePath);
      await refreshCurrentUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    _setLoading(true);
    try {
      final user = await authRepository.restoreSession();
      _currentUser = user;
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await authRepository.login(email, password, expectedRole);
      if (user == null) {
        _errorMessage = 'Invalid email, password, or account role.';
        _setLoading(false);
        return false;
      }
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? specialty,
    String? room,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await authRepository.registerUser(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        specialty: specialty,
        room: room,
      );
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      if (e.toString().contains('Email already exists')) {
        _errorMessage = 'An account with this email already exists.';
      } else {
        _errorMessage = 'Registration failed: ${e.toString()}';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await authRepository.clearSession();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile(String fullName, String email) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      await authRepository.updateUserProfile(_currentUser!.id!, fullName, email);
      _currentUser = _currentUser!.copyWith(fullName: fullName, email: email);
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
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    if (!_disposed) {
      notifyListeners();
    }
  }
}
