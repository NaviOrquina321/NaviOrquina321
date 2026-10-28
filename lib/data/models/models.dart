class User {
  final int? id;
  final String role; // 'patient' or 'doctor'
  final String fullName;
  final String email;
  final String passwordHash;
  final String salt;
  final String createdAt;

  User({
    this.id,
    required this.role,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'role': role,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      role: map['role'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  User copyWith({
    int? id,
    String? role,
    String? fullName,
    String? email,
    String? passwordHash,
    String? salt,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ChatMessage {
  final int? id;
  final int appointmentId;
  final int senderId;
  final String text;
  final String createdAt;

  ChatMessage({
    this.id,
    required this.appointmentId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'appointment_id': appointmentId,
      'sender_id': senderId,
      'text': text,
      'created_at': createdAt,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      appointmentId: map['appointment_id'] as int,
      senderId: map['sender_id'] as int,
      text: map['text'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}

class SupportMessage {
  final int? id;
  final int? userId;
  final String text;
  final String sender; // 'user' or 'support'
  final String createdAt;

  SupportMessage({
    this.id,
    this.userId,
    required this.text,
    required this.sender,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'text': text,
      'sender': sender,
      'created_at': createdAt,
    };
  }

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      text: map['text'] as String,
      sender: map['sender'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}

class SupportTicket {
  final int? id;
  final int userId;
  final String category;
  final String description;
  final String status; // 'open' or 'resolved'
  final String createdAt;

  SupportTicket({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    this.status = 'open',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'description': description,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      category: map['category'] as String,
      description: map['description'] as String,
      status: (map['status'] as String?) ?? 'open',
      createdAt: map['created_at'] as String,
    );
  }
}

class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final String forRole; // 'patient', 'doctor', or 'all'

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.forRole = 'all',
  });
}

class Doctor {
  final int? id;
  final int userId;
  final String? specialty;
  final String? room;
  final String? bio;
  final double rating;
  final int yearsExperience;
  final int patientsCount;
  final int autoConfirm; // 1 or 0
  final double consultationFee;
  final User? user;

  Doctor({
    this.id,
    required this.userId,
    this.specialty,
    this.room,
    this.bio,
    this.rating = 5.0,
    this.yearsExperience = 0,
    this.patientsCount = 0,
    this.autoConfirm = 1,
    this.consultationFee = 500.0,
    this.user,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'specialty': specialty,
      'room': room,
      'bio': bio,
      'rating': rating,
      'years_experience': yearsExperience,
      'patients_count': patientsCount,
      'auto_confirm': autoConfirm,
      'consultation_fee': consultationFee,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map, {User? user}) {
    return Doctor(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      specialty: map['specialty'] as String?,
      room: map['room'] as String?,
      bio: map['bio'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      yearsExperience: (map['years_experience'] as int?) ?? 0,
      patientsCount: (map['patients_count'] as int?) ?? 0,
      autoConfirm: (map['auto_confirm'] as int?) ?? 1,
      consultationFee: (map['consultation_fee'] as num?)?.toDouble() ?? 500.0,
      user: user,
    );
  }

  Doctor copyWith({
    int? id,
    int? userId,
    String? specialty,
    String? room,
    String? bio,
    double? rating,
    int? yearsExperience,
    int? patientsCount,
    int? autoConfirm,
    double? consultationFee,
    User? user,
  }) {
    return Doctor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialty: specialty ?? this.specialty,
      room: room ?? this.room,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      patientsCount: patientsCount ?? this.patientsCount,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      consultationFee: consultationFee ?? this.consultationFee,
      user: user ?? this.user,
    );
  }
}

class Availability {
  final int? id;
  final int doctorId;
  final int weekday; // 1-7 (Mon-Sun)
  final String startTime; // 'HH:mm'
  final String endTime; // 'HH:mm'
  final int isEnabled; // 1 or 0
  final int slotMinutes; // default 30

  Availability({
    this.id,
    required this.doctorId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.isEnabled,
    this.slotMinutes = 30,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'doctor_id': doctorId,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'is_enabled': isEnabled,
      'slot_minutes': slotMinutes,
    };
  }

  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      id: map['id'] as int?,
      doctorId: map['doctor_id'] as int,
      weekday: map['weekday'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      isEnabled: map['is_enabled'] as int,
      slotMinutes: (map['slot_minutes'] as int?) ?? 30,
    );
  }

  Availability copyWith({
    int? id,
    int? doctorId,
    int? weekday,
    String? startTime,
    String? endTime,
    int? isEnabled,
    int? slotMinutes,
  }) {
    return Availability(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isEnabled: isEnabled ?? this.isEnabled,
      slotMinutes: slotMinutes ?? this.slotMinutes,
    );
  }
}

class Appointment {
  final int? id;
  final int patientId;
  final int doctorId;
  final String date; // 'yyyy-MM-dd'
  final String time; // 'HH:mm'
  final String? reason;
  final String status; // 'pending','confirmed','in_progress','completed','cancelled','declined'
  final String? notes;
  final String? nextVisit;
  final String createdAt;
  final String visitType; // 'In person' or 'Video call'
  final String? paymentMethod; // 'GCash', 'Cash', 'Card'
  final String? paymentStatus; // 'paid', 'pay at clinic'
  final double amount;
  final String? meetingLink;
  final User? patientUser;
  final Doctor? doctor;

  Appointment({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.time,
    this.reason,
    required this.status,
    this.notes,
    this.nextVisit,
    required this.createdAt,
    this.visitType = 'In person',
    this.paymentMethod,
    this.paymentStatus,
    this.amount = 500.0,
    this.meetingLink,
    this.patientUser,
    this.doctor,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'date': date,
      'time': time,
      'reason': reason,
      'status': status,
      'notes': notes,
      'next_visit': nextVisit,
      'created_at': createdAt,
      'visit_type': visitType,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'amount': amount,
      'meeting_link': meetingLink,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map, {User? patientUser, Doctor? doctor}) {
    return Appointment(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      doctorId: map['doctor_id'] as int,
      date: map['date'] as String,
      time: map['time'] as String,
      reason: map['reason'] as String?,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      nextVisit: map['next_visit'] as String?,
      createdAt: map['created_at'] as String,
      visitType: (map['visit_type'] as String?) ?? 'In person',
      paymentMethod: map['payment_method'] as String?,
      paymentStatus: map['payment_status'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 500.0,
      meetingLink: map['meeting_link'] as String?,
      patientUser: patientUser,
      doctor: doctor,
    );
  }

  Appointment copyWith({
    int? id,
    int? patientId,
    int? doctorId,
    String? date,
    String? time,
    String? reason,
    String? status,
    String? notes,
    String? nextVisit,
    String? createdAt,
    String? visitType,
    String? paymentMethod,
    String? paymentStatus,
    double? amount,
    String? meetingLink,
    User? patientUser,
    Doctor? doctor,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      time: time ?? this.time,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      nextVisit: nextVisit ?? this.nextVisit,
      createdAt: createdAt ?? this.createdAt,
      visitType: visitType ?? this.visitType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amount: amount ?? this.amount,
      meetingLink: meetingLink ?? this.meetingLink,
      patientUser: patientUser ?? this.patientUser,
      doctor: doctor ?? this.doctor,
    );
  }
}

class MedicalRecord {
  final int? id;
  final int patientId;
  final String title;
  final String type; // 'visit', 'prescription', 'result'
  final String filePath;
  final String createdAt;

  MedicalRecord({
    this.id,
    required this.patientId,
    required this.title,
    required this.type,
    required this.filePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'title': title,
      'type': type,
      'file_path': filePath,
      'created_at': createdAt,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      title: map['title'] as String,
      type: map['type'] as String,
      filePath: map['file_path'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}

class UserSettings {
  final int userId;
  final bool remindersOn;
  final bool chatOn;
  final bool offersOn;
  final String remindBefore; // '1 hour' or '1 day'

  UserSettings({
    required this.userId,
    this.remindersOn = true,
    this.chatOn = true,
    this.offersOn = true,
    this.remindBefore = '1 hour',
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'reminders_on': remindersOn ? 1 : 0,
      'chat_on': chatOn ? 1 : 0,
      'offers_on': offersOn ? 1 : 0,
      'remind_before': remindBefore,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: map['user_id'] as int,
      remindersOn: (map['reminders_on'] as int?) != 0,
      chatOn: (map['chat_on'] as int?) != 0,
      offersOn: (map['offers_on'] as int?) != 0,
      remindBefore: (map['remind_before'] as String?) ?? '1 hour',
    );
  }

  UserSettings copyWith({
    int? userId,
    bool? remindersOn,
    bool? chatOn,
    bool? offersOn,
    String? remindBefore,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      remindersOn: remindersOn ?? this.remindersOn,
      chatOn: chatOn ?? this.chatOn,
      offersOn: offersOn ?? this.offersOn,
      remindBefore: remindBefore ?? this.remindBefore,
    );
  }
}

class Prescription {
  final int? id;
  final int appointmentId;
  final String medicine;

  Prescription({
    this.id,
    required this.appointmentId,
    required this.medicine,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'appointment_id': appointmentId,
      'medicine': medicine,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as int?,
      appointmentId: map['appointment_id'] as int,
      medicine: map['medicine'] as String,
    );
  }
}

class Review {
  final int? id;
  final int appointmentId;
  final int patientId;
  final int doctorId;
  final int rating; // 1-5
  final String? tags;
  final String? comment;
  final String createdAt;
  final User? patientUser;

  Review({
    this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.rating,
    this.tags,
    this.comment,
    required this.createdAt,
    this.patientUser,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'created_at': createdAt,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, {User? patientUser}) {
    return Review(
      id: map['id'] as int?,
      appointmentId: map['appointment_id'] as int,
      patientId: map['patient_id'] as int,
      doctorId: map['doctor_id'] as int,
      rating: map['rating'] as int,
      tags: map['tags'] as String?,
      comment: map['comment'] as String?,
      createdAt: map['created_at'] as String,
      patientUser: patientUser,
    );
  }
}

class AppNotification {
  final int? id;
  final int userId;
  final String type;
  final String title;
  final String body;
  final int isRead; // 0 or 1
  final String createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      isRead: (map['is_read'] as int?) ?? 0,
      createdAt: map['created_at'] as String,
    );
  }

  AppNotification copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? body,
    int? isRead,
    String? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
