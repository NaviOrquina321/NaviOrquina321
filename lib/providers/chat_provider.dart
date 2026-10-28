import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository chatRepository;

  List<ChatMessage> _messages = [];
  String? _patientNote;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  ChatProvider({ChatRepository? chatRepository})
      : chatRepository = chatRepository ?? ChatRepository();

  List<ChatMessage> get messages => _messages;
  String? get patientNote => _patientNote;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchMessages(int appointmentId) async {
    _setLoading(true);
    try {
      _messages = await chatRepository.getAppointmentMessages(appointmentId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> sendMessage({
    required int appointmentId,
    required int senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;
    try {
      final msg = await chatRepository.sendMessage(
        appointmentId: appointmentId,
        senderId: senderId,
        text: text,
      );
      if (msg != null) {
        _messages.add(msg);
        if (!_disposed) notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<void> fetchPatientNote({required int doctorId, required int patientId}) async {
    try {
      _patientNote = await chatRepository.getPatientNote(doctorId: doctorId, patientId: patientId);
      if (!_disposed) notifyListeners();
    } catch (_) {}
  }

  Future<bool> savePatientNote({
    required int doctorId,
    required int patientId,
    required String note,
  }) async {
    try {
      await chatRepository.savePatientNote(doctorId: doctorId, patientId: patientId, note: note);
      _patientNote = note.trim();
      if (!_disposed) notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (!_disposed) notifyListeners();
  }
}
