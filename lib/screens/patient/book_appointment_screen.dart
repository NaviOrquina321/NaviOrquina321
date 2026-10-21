import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../data/models/models.dart';
import '../../data/repositories/availability_repository.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  final int doctorId;
  final int? rescheduleAppointmentId;

  const BookAppointmentScreen({
    super.key,
    required this.doctorId,
    this.rescheduleAppointmentId,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _reasonController = TextEditingController();
  List<DateTime> _availableDates = [];
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  List<Availability> _availabilities = [];
  List<String> _morningSlots = [];
  List<String> _afternoonSlots = [];
  bool _loadingAvailability = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).fetchDoctorDetails(widget.doctorId);
      _loadAvailabilityAndDates();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilityAndDates() async {
    final availRepo = AvailabilityRepository();
    final list = await availRepo.getDoctorAvailability(widget.doctorId);
    _availabilities = list;

    final List<DateTime> dates = [];
    DateTime candidate = DateTime.now();
    while (dates.length < 5) {
      final weekday = candidate.weekday;
      final dayAvail = list.firstWhere(
        (a) => a.weekday == weekday,
        orElse: () => Availability(
          doctorId: widget.doctorId,
          weekday: weekday,
          startTime: '09:00',
          endTime: '17:00',
          isEnabled: 0,
        ),
      );

      if (dayAvail.isEnabled == 1) {
        dates.add(candidate);
      }
      candidate = candidate.add(const Duration(days: 1));
    }

    setState(() {
      _availableDates = dates;
      if (dates.isNotEmpty) {
        _selectedDate = dates.first;
        _generateSlotsForSelectedDate();
      }
      _loadingAvailability = false;
    });
  }

  void _generateSlotsForSelectedDate() async {
    if (_selectedDate == null) return;

    final dateStr = DateTimeUtils.formatSqlDate(_selectedDate!);
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    await apptProvider.fetchBookedSlots(widget.doctorId, dateStr);

    final weekday = _selectedDate!.weekday;
    final dayAvail = _availabilities.firstWhere(
      (a) => a.weekday == weekday,
      orElse: () => Availability(
        doctorId: widget.doctorId,
        weekday: weekday,
        startTime: '09:00',
        endTime: '17:00',
        isEnabled: 0,
      ),
    );

    if (dayAvail.isEnabled == 0) {
      setState(() {
        _morningSlots = [];
        _afternoonSlots = [];
      });
      return;
    }

    final morning = <String>[];
    final afternoon = <String>[];

    final startParts = dayAvail.startTime.split(':');
    final endParts = dayAvail.endTime.split(':');

    var current = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final end = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    final now = DateTime.now();

    while (current.isBefore(end)) {
      final slot24 = DateFormat('HH:mm').format(current);

      final isToday = _selectedDate!.year == now.year &&
          _selectedDate!.month == now.month &&
          _selectedDate!.day == now.day;
      final isPast = isToday && current.isBefore(now);

      if (!isPast) {
        if (current.hour < 12) {
          morning.add(slot24);
        } else {
          afternoon.add(slot24);
        }
      }

      current = current.add(Duration(minutes: dayAvail.slotMinutes));
    }

    setState(() {
      _morningSlots = morning;
      _afternoonSlots = afternoon;
      _selectedTimeSlot = null;
    });
  }

  Future<void> _handleConfirmBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final patientId = authProvider.currentUser?.id;

    if (patientId == null) return;

    final dateStr = DateTimeUtils.formatSqlDate(_selectedDate!);

    if (widget.rescheduleAppointmentId != null) {
      final success = await apptProvider.rescheduleAppointment(
        widget.rescheduleAppointmentId!,
        dateStr,
        _selectedTimeSlot!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment rescheduled successfully!')),
          );
          Navigator.pop(context);
        } else if (apptProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apptProvider.errorMessage!)),
          );
        }
      }
    } else {
      final appt = await apptProvider.bookAppointment(
        patientId: patientId,
        doctorId: widget.doctorId,
        date: dateStr,
        time: _selectedTimeSlot!,
        reason: _reasonController.text.trim().isEmpty ? 'General Consultation' : _reasonController.text.trim(),
      );

      if (mounted) {
        if (appt != null) {
          Navigator.pushReplacementNamed(
            context,
            RouteNames.bookingConfirmed,
            arguments: appt.id,
          );
        } else if (apptProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apptProvider.errorMessage!)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final doc = doctorProvider.selectedDoctor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.rescheduleAppointmentId != null ? 'Reschedule Visit' : 'Book Appointment'),
      ),
      body: _loadingAvailability || doc == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildStepBar('Doctor', true),
                              const SizedBox(width: 8),
                              _buildStepBar('Date & Time', true),
                              const SizedBox(width: 8),
                              _buildStepBar('Confirm', _selectedTimeSlot != null),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  AvatarInitials(name: doc.user?.fullName ?? 'Doctor', radius: 24),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.user?.fullName ?? 'Dr. Medical',
                                        style: const TextStyle(
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        doc.specialty ?? 'General Medicine',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Select Date',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 70,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availableDates.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final d = _availableDates[index];
                                final isSel = _selectedDate != null &&
                                    d.year == _selectedDate!.year &&
                                    d.month == _selectedDate!.month &&
                                    d.day == _selectedDate!.day;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = d;
                                      _generateSlotsForSelectedDate();
                                    });
                                  },
                                  child: Container(
                                    width: 60,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.blue : AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSel ? AppColors.blue : AppColors.line,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateFormat('EEE').format(d),
                                          style: TextStyle(
                                            color: isSel ? AppColors.white : AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('d').format(d),
                                          style: TextStyle(
                                            color: isSel ? AppColors.white : AppColors.navy,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_morningSlots.isNotEmpty) ...[
                            const Text(
                              'Morning Slots',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _morningSlots.map((slot) => _buildSlotChip(slot, apptProvider.bookedSlots.contains(slot))).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (_afternoonSlots.isNotEmpty) ...[
                            const Text(
                              'Afternoon Slots',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _afternoonSlots.map((slot) => _buildSlotChip(slot, apptProvider.bookedSlots.contains(slot))).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          TextField(
                            controller: _reasonController,
                            decoration: const InputDecoration(
                              labelText: 'Reason for visit (optional)',
                              hintText: 'e.g., Routine checkup, chest pain',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedDate != null && _selectedTimeSlot != null) ...[
                          Text(
                            'Selected: ${DateTimeUtils.formatDateAndSlot(DateTimeUtils.formatSqlDate(_selectedDate!), _selectedTimeSlot!)}',
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        AppButton(
                          text: widget.rescheduleAppointmentId != null ? 'Confirm Reschedule' : 'Confirm Booking',
                          isLoading: apptProvider.isLoading,
                          onPressed: _selectedTimeSlot == null ? null : _handleConfirmBooking,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepBar(String title, bool active) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppColors.blue : AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: active ? AppColors.navy : AppColors.muted,
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotChip(String slot24, bool isBooked) {
    final displayTime = DateTimeUtils.formatTime(slot24);
    final isSelected = _selectedTimeSlot == slot24;

    return GestureDetector(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                _selectedTimeSlot = slot24;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue
              : isBooked
                  ? AppColors.tint
                  : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.blue
                : isBooked
                    ? AppColors.tile
                    : AppColors.line,
          ),
        ),
        child: Text(
          displayTime,
          style: TextStyle(
            color: isSelected
                ? AppColors.white
                : isBooked
                    ? AppColors.muted
                    : AppColors.navy,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            decoration: isBooked ? TextDecoration.lineThrough : TextDecoration.none,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
