import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/support_repository.dart';

class SupportProvider extends ChangeNotifier {
  final SupportRepository supportRepository;

  List<FaqItem> _faqs = [];
  final Map<String, bool> _votedFaqs = {};
  List<SupportMessage> _messages = [];
  List<SupportTicket> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  SupportProvider({SupportRepository? supportRepository})
      : supportRepository = supportRepository ?? SupportRepository();

  List<FaqItem> get faqs => _faqs;
  Map<String, bool> get votedFaqs => _votedFaqs;
  List<SupportMessage> get messages => _messages;
  List<SupportTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void fetchFaqs({required String role, String? query}) {
    _faqs = supportRepository.getFaqs(role: role, query: query);
    if (!_disposed) notifyListeners();
  }

  Future<void> checkFaqVoteStatus(String faqId, int userId) async {
    final voted = await supportRepository.hasUserVotedFaq(faqId, userId);
    if (voted) {
      _votedFaqs[faqId] = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> voteFaq({
    required String faqId,
    required int userId,
    required bool helpful,
  }) async {
    final success = await supportRepository.saveFaqFeedback(
      faqId: faqId,
      userId: userId,
      helpful: helpful,
    );
    if (success) {
      _votedFaqs[faqId] = true;
      if (!_disposed) notifyListeners();
    }
    return success;
  }

  Future<void> fetchSupportMessages(int? userId) async {
    _setLoading(true);
    try {
      await supportRepository.ensureWelcomeMessage(userId);
      _messages = await supportRepository.getSupportMessages(userId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> sendMessage({required int? userId, required String text}) async {
    if (text.trim().isEmpty) return false;
    try {
      await supportRepository.sendMessage(userId: userId, text: text);
      _messages = await supportRepository.getSupportMessages(userId);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<void> clearSupportMessages(int? userId) async {
    _setLoading(true);
    try {
      await supportRepository.clearSupportMessages(userId);
      await supportRepository.ensureWelcomeMessage(userId);
      _messages = await supportRepository.getSupportMessages(userId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<SupportTicket?> createSupportTicket({
    required int userId,
    required String category,
    required String description,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final ticket = await supportRepository.createSupportTicket(
        userId: userId,
        category: category,
        description: description,
      );
      await fetchUserTickets(userId);
      _setLoading(false);
      return ticket;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  Future<void> fetchUserTickets(int userId) async {
    try {
      _tickets = await supportRepository.getUserSupportTickets(userId);
      if (!_disposed) notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (!_disposed) notifyListeners();
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
