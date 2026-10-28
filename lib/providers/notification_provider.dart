import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository notificationRepository;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  NotificationProvider({NotificationRepository? notificationRepository})
      : notificationRepository = notificationRepository ?? NotificationRepository();

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications(int userId) async {
    _setLoading(true);
    try {
      _notifications = await notificationRepository.getUserNotifications(userId);
      _unreadCount = await notificationRepository.getUnreadCount(userId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> markAsRead(int notificationId, int userId) async {
    try {
      await notificationRepository.markAsRead(notificationId);
      await fetchNotifications(userId);
    } catch (_) {}
  }

  Future<void> markAllAsRead(int userId) async {
    try {
      await notificationRepository.markAllAsRead(userId);
      await fetchNotifications(userId);
    } catch (_) {}
  }

  Future<void> clearAllNotifications(int userId) async {
    try {
      await notificationRepository.clearAllNotifications(userId);
      await fetchNotifications(userId);
    } catch (_) {}
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (!_disposed) notifyListeners();
  }
}
