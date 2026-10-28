import '../db/database_helper.dart';
import '../models/models.dart';

class SupportRepository {
  final DatabaseHelper dbHelper;

  SupportRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const List<FaqItem> allFaqs = [
    // Patient FAQs
    FaqItem(
      id: 'p1',
      category: 'Booking',
      forRole: 'patient',
      question: 'How to book an appointment?',
      answer: 'Navigate to Home or Doctors, select your preferred doctor, pick an available date and time slot, and tap Confirm.',
    ),
    FaqItem(
      id: 'p2',
      category: 'Visits',
      forRole: 'patient',
      question: 'How do I cancel or reschedule a visit?',
      answer: 'Go to My Visits, tap on the appointment, and select Cancel or Reschedule to choose a new time.',
    ),
    FaqItem(
      id: 'p3',
      category: 'Chat & Video',
      forRole: 'patient',
      question: 'When does the doctor chat open and close?',
      answer: 'The chat opens once an appointment is confirmed and stays active until the consultation is completed or cancelled.',
    ),
    FaqItem(
      id: 'p4',
      category: 'Chat & Video',
      forRole: 'patient',
      question: 'How do video call appointments work?',
      answer: 'On your appointment time, open Visit Details or Doctor Consultation and tap "Join video call" or "Start call" to connect.',
    ),
    FaqItem(
      id: 'p5',
      category: 'Payment',
      forRole: 'patient',
      question: 'How does payment work?',
      answer: 'Select GCash, Card, or Cash at clinic during booking. In this demo, payments are simulated and no real charges occur.',
    ),
    FaqItem(
      id: 'p6',
      category: 'Account',
      forRole: 'patient',
      question: 'What if I forgot my password?',
      answer: 'Tap "Forgot password?" on the Login screen, enter your registered email address, and set a new password.',
    ),
    FaqItem(
      id: 'p7',
      category: 'Medical Records',
      forRole: 'patient',
      question: 'Where can I find my medical records?',
      answer: 'Go to Profile or Visit Details to view summaries, doctor notes, and prescribed medications.',
    ),
    FaqItem(
      id: 'p8',
      category: 'Reviews',
      forRole: 'patient',
      question: 'How do I rate my doctor after a visit?',
      answer: 'Once your visit status is marked Completed, go to My Visits > Past or Reminders and tap "Rate visit".',
    ),

    // Doctor FAQs
    FaqItem(
      id: 'd1',
      category: 'Dashboard',
      forRole: 'doctor',
      question: 'How do I accept or decline appointment requests?',
      answer: 'On your Doctor Dashboard under "Later today" or pending requests, tap Accept or Decline.',
    ),
    FaqItem(
      id: 'd2',
      category: 'Availability',
      forRole: 'doctor',
      question: 'How do I set my availability and working hours?',
      answer: 'Go to the Hours tab, enable your working weekdays, select start and end times, and save changes.',
    ),
    FaqItem(
      id: 'd3',
      category: 'Consultation',
      forRole: 'doctor',
      question: 'How do I start and complete a consultation?',
      answer: 'From your Schedule, tap "Start consultation" on the Next Patient card. Fill in visit notes, add prescriptions, and tap "Complete visit".',
    ),
    FaqItem(
      id: 'd4',
      category: 'Prescriptions',
      forRole: 'doctor',
      question: 'How do I add prescriptions to a visit?',
      answer: 'Inside Consultation, tap "+ Add medicine", enter the medicine details, and tap Add.',
    ),
    FaqItem(
      id: 'd5',
      category: 'Booking Requests',
      forRole: 'doctor',
      question: 'How do I suggest a new appointment time?',
      answer: 'When reviewing a booking request, tap "Suggest new time", select a new slot, and the patient will be notified.',
    ),
    FaqItem(
      id: 'd6',
      category: 'Patient Notes',
      forRole: 'doctor',
      question: 'Where do I save patient private notes?',
      answer: 'Inside Consultation or Patient Details, enter notes in the Doctor Notes box. They are saved securely to the visit record.',
    ),
  ];

  List<FaqItem> getFaqs({required String role, String? query}) {
    List<FaqItem> roleFaqs = allFaqs.where((f) => f.forRole == role || f.forRole == 'all').toList();
    if (query == null || query.trim().isEmpty) {
      return roleFaqs;
    }
    final q = query.trim().toLowerCase();
    return roleFaqs.where((f) {
      return f.question.toLowerCase().contains(q) || f.answer.toLowerCase().contains(q);
    }).toList();
  }

  Future<bool> saveFaqFeedback({
    required String faqId,
    required int userId,
    required bool helpful,
  }) async {
    final db = await dbHelper.database;
    try {
      await db.insert('faq_feedback', {
        'faq_id': faqId,
        'user_id': userId,
        'helpful': helpful ? 1 : 0,
      });
      return true;
    } catch (_) {
      return false; // Already voted or constraint failure
    }
  }

  Future<bool> hasUserVotedFaq(String faqId, int userId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'faq_feedback',
      where: 'faq_id = ? AND user_id = ?',
      whereArgs: [faqId, userId],
    );
    return res.isNotEmpty;
  }

  Future<List<SupportMessage>> getSupportMessages(int? userId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'support_messages',
      where: userId != null ? 'user_id = ? OR user_id IS NULL' : 'user_id IS NULL',
      whereArgs: userId != null ? [userId] : [],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => SupportMessage.fromMap(m)).toList();
  }

  Future<void> ensureWelcomeMessage(int? userId) async {
    final db = await dbHelper.database;
    final existing = await db.query(
      'support_messages',
      where: userId != null ? 'user_id = ?' : 'user_id IS NULL',
      whereArgs: userId != null ? [userId] : [],
    );
    if (existing.isEmpty) {
      await db.insert('support_messages', {
        'user_id': userId,
        'text': 'Hi! How can we help you today?',
        'sender': 'support',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<SupportMessage?> sendMessage({
    required int? userId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    // Insert user message
    final userMsgId = await db.insert('support_messages', {
      'user_id': userId,
      'text': trimmed,
      'sender': 'user',
      'created_at': nowStr,
    });

    // Auto reply logic based on keywords
    final lower = trimmed.toLowerCase();
    String replyText;
    if (lower.contains('book') || lower.contains('appointment')) {
      replyText = 'For booking help, go to Home or Doctors tab, select a doctor and pick an available time slot.';
    } else if (lower.contains('cancel') || lower.contains('reschedule')) {
      replyText = 'To cancel or reschedule, open My Visits, tap the appointment, and choose Cancel or Reschedule.';
    } else if (lower.contains('pay')) {
      replyText = 'Payments in this app are simulated demo transactions. You can select GCash, Card, or Cash.';
    } else if (lower.contains('password')) {
      replyText = 'To reset your password, tap "Forgot password?" on the Login screen and follow the prompt.';
    } else if (lower.contains('video')) {
      replyText = 'Video calls open at the appointment time. Tap "Join video call" on your visit details.';
    } else {
      replyText = 'Thanks! We\'ll get back to you within 24 hours.';
    }

    final replyTime = DateTime.now().add(const Duration(milliseconds: 100)).toIso8601String();
    await db.insert('support_messages', {
      'user_id': userId,
      'text': replyText,
      'sender': 'support',
      'created_at': replyTime,
    });

    return SupportMessage(
      id: userMsgId,
      userId: userId,
      text: trimmed,
      sender: 'user',
      createdAt: nowStr,
    );
  }

  Future<void> clearSupportMessages(int? userId) async {
    final db = await dbHelper.database;
    await db.delete(
      'support_messages',
      where: userId != null ? 'user_id = ?' : 'user_id IS NULL',
      whereArgs: userId != null ? [userId] : [],
    );
  }

  Future<SupportTicket> createSupportTicket({
    required int userId,
    required String category,
    required String description,
  }) async {
    final trimmedDesc = description.trim();
    if (trimmedDesc.length < 10) {
      throw Exception('Description must be at least 10 characters long.');
    }

    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    final ticketId = await db.insert('support_tickets', {
      'user_id': userId,
      'category': category,
      'description': trimmedDesc,
      'status': 'open',
      'created_at': nowStr,
    });

    return SupportTicket(
      id: ticketId,
      userId: userId,
      category: category,
      description: trimmedDesc,
      status: 'open',
      createdAt: nowStr,
    );
  }

  Future<List<SupportTicket>> getUserSupportTickets(int userId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'support_tickets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((t) => SupportTicket.fromMap(t)).toList();
  }
}
