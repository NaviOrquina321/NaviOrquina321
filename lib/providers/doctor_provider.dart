import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/doctor_repository.dart';

class DoctorProvider extends ChangeNotifier {
  final DoctorRepository doctorRepository;

  List<Doctor> _doctors = [];
  List<String> _specialties = ['All'];
  List<Review> _doctorReviews = [];
  Doctor? _selectedDoctor;
  Doctor? _currentDoctorProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  DoctorProvider({DoctorRepository? doctorRepository})
      : doctorRepository = doctorRepository ?? DoctorRepository();

  List<Doctor> get doctors => _doctors;
  List<String> get specialties => _specialties;
  List<Review> get doctorReviews => _doctorReviews;
  Doctor? get selectedDoctor => _selectedDoctor;
  Doctor? get currentDoctorProfile => _currentDoctorProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDoctors({String? searchQuery, String? specialty}) async {
    _setLoading(true);
    try {
      _doctors = await doctorRepository.getAllDoctors(
        searchQuery: searchQuery,
        specialty: specialty,
      );
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchSpecialties() async {
    try {
      final list = await doctorRepository.getAllSpecialties();
      _specialties = ['All', ...list];
      if (!_disposed) notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchDoctorDetails(int doctorId) async {
    _setLoading(true);
    try {
      _selectedDoctor = await doctorRepository.getDoctorById(doctorId);
      if (_selectedDoctor != null) {
        _doctorReviews = await doctorRepository.getReviewsForDoctor(doctorId);
      } else {
        _doctorReviews = [];
      }
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchDoctorProfileForUser(int userId) async {
    _setLoading(true);
    try {
      _currentDoctorProfile = await doctorRepository.getDoctorByUserId(userId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> updateDoctorProfile(int doctorId, {String? specialty, String? room, String? bio, bool? autoConfirm}) async {
    _setLoading(true);
    try {
      await doctorRepository.updateDoctorProfile(
        doctorId,
        specialty: specialty,
        room: room,
        bio: bio,
        autoConfirm: autoConfirm,
      );
      if (_currentDoctorProfile != null && _currentDoctorProfile!.id == doctorId) {
        _currentDoctorProfile = _currentDoctorProfile!.copyWith(
          specialty: specialty,
          room: room,
          bio: bio,
          autoConfirm: autoConfirm != null ? (autoConfirm ? 1 : 0) : null,
        );
      }
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
}
