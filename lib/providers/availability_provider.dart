import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/availability_repository.dart';

class AvailabilityProvider extends ChangeNotifier {
  final AvailabilityRepository availabilityRepository;

  List<Availability> _availabilities = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  AvailabilityProvider({AvailabilityRepository? availabilityRepository})
      : availabilityRepository = availabilityRepository ?? AvailabilityRepository();

  List<Availability> get availabilities => _availabilities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDoctorAvailability(int doctorId) async {
    _setLoading(true);
    try {
      _availabilities = await availabilityRepository.getDoctorAvailability(doctorId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> saveAvailability(int doctorId, List<Availability> availabilities) async {
    _setLoading(true);
    try {
      await availabilityRepository.saveDoctorAvailability(doctorId, availabilities);
      _availabilities = availabilities;
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
