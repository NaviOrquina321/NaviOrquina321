import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  static String formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2024, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time24;
    }
  }

  static String formatDateAndSlot(String dateStr, String timeStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final formattedDate = DateFormat('EEE, MMM d').format(dt);
      final formattedTime = formatTime(timeStr);
      return '$formattedDate · $formattedTime';
    } catch (_) {
      return '$dateStr · $timeStr';
    }
  }

  static String formatSqlDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

class Validators {
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }
}
