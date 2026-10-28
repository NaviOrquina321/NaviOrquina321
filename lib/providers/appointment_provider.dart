import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/appointment_repository.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentRepository appointmentRepository;

  List<Appointment> _upcomingAppointments = [];
  List<Appointment> _pastAppointments = [];
  List<Appointment> _patientAppointments = [];
  List<Appointment> _doctorAppointments = [];
  Appointment? _selectedAppointment;
  List<Prescription> _selectedPrescriptions = [];
  List<String> _bookedSlots = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  AppointmentProvider({AppointmentRepository? appointmentRepository})
      : appointmentRepository = appointmentRepository ?? AppointmentRepository();

  List<Appointment> get upcomingAppointments => _upcomingAppointments;
  List<Appointment> get pastAppointments => _pastAppointments;
  List<Appointment> get patientAppointments => _patientAppointments;
  List<Appointment> get doctorAppointments => _doctorAppointments;
  Appointment? get selectedAppointment => _selectedAppointment;
  List<Prescription> get selectedPrescriptions => _selectedPrescriptions;
  List<String> get bookedSlots => _bookedSlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Appointment? get nextUpcomingAppointment {
    if (_upcomingAppointments.isEmpty) return null;
    final confirmed = _upcomingAppointments.where((a) => a.status == 'confirmed').toList();
    if (confirmed.isEmpty) return null;
    return confirmed.first;
  }

  Future<void> fetchPatientAppointments(int patientId, {String? dateFilter}) async {
    _setLoading(true);
    try {
      _patientAppointments = await appointmentRepository.getPatientAppointments(patientId, past: false, dateFilter: dateFilter);
      _upcomingAppointments = await appointmentRepository.getPatientAppointments(patientId, past: false);
      _pastAppointments = await appointmentRepository.getPatientAppointments(patientId, past: true);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> markArrived({
    required int appointmentId,
    required String arrivedAt,
    required int doctorUserId,
    required String patientName,
  }) async {
    _setLoading(true);
    try {
      await appointmentRepository.markArrived(
        appointmentId: appointmentId,
        arrivedAt: arrivedAt,
        doctorUserId: doctorUserId,
        patientName: patientName,
      );
      if (_selectedAppointment?.id == appointmentId) {
        _selectedAppointment = _selectedAppointment!.copyWith(arrivedAt: arrivedAt);
      }
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchDoctorAppointments(int doctorId, {String? dateFilter, String? filterType}) async {
    _setLoading(true);
    try {
      _doctorAppointments = await appointmentRepository.getDoctorAppointments(
        doctorId,
        dateFilter: dateFilter,
        filterType: filterType,
      );
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchAppointmentDetails(int appointmentId) async {
    _setLoading(true);
    try {
      _selectedAppointment = await appointmentRepository.getAppointmentById(appointmentId);
      _selectedPrescriptions = await appointmentRepository.getPrescriptionsForAppointment(appointmentId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchBookedSlots(int doctorId, String date) async {
    try {
      _bookedSlots = await appointmentRepository.getBookedSlotsForDoctorAndDate(doctorId, date);
      if (!_disposed) notifyListeners();
    } catch (_) {
      _bookedSlots = [];
      if (!_disposed) notifyListeners();
    }
  }

  Future<Appointment?> bookAppointment({
    required int patientId,
    required int doctorId,
    required String date,
    required String time,
    String? reason,
    String visitType = 'In person',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final appt = await appointmentRepository.createAppointment(
        patientId: patientId,
        doctorId: doctorId,
        date: date,
        time: time,
        reason: reason,
        visitType: visitType,
      );
      _setLoading(false);
      return appt;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> savePaymentInfo({
    required int appointmentId,
    required String paymentMethod,
    required String paymentStatus,
    required double amount,
  }) async {
    _setLoading(true);
    try {
      await appointmentRepository.savePaymentInfo(appointmentId, paymentMethod, paymentStatus, amount);
      if (_selectedAppointment?.id == appointmentId) {
        _selectedAppointment = _selectedAppointment!.copyWith(
          paymentMethod: paymentMethod,
          paymentStatus: paymentStatus,
          amount: amount,
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

  Future<bool> saveMeetingLink(int appointmentId, String meetingLink) async {
    try {
      await appointmentRepository.saveMeetingLink(appointmentId, meetingLink);
      if (_selectedAppointment?.id == appointmentId) {
        _selectedAppointment = _selectedAppointment!.copyWith(meetingLink: meetingLink);
      }
      if (!_disposed) notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus({
    required int appointmentId,
    required String status,
    required int notifyUserId,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    _setLoading(true);
    try {
      await appointmentRepository.updateAppointmentStatus(
        appointmentId,
        status,
        notifyUserId: notifyUserId,
        notificationTitle: notificationTitle,
        notificationBody: notificationBody,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> rescheduleAppointment(int appointmentId, String date, String time) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await appointmentRepository.rescheduleAppointment(appointmentId, date, time);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> completeConsultation({
    required int appointmentId,
    required String notes,
    required List<String> medicines,
    String? nextVisit,
  }) async {
    _setLoading(true);
    try {
      await appointmentRepository.completeConsultation(
        appointmentId: appointmentId,
        notes: notes,
        medicines: medicines,
        nextVisit: nextVisit,
      );
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
    notifyListeners();
  }
}
