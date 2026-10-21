import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/status_pill.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';

class VisitDetailsScreen extends StatefulWidget {
  final int appointmentId;

  const VisitDetailsScreen({super.key, required this.appointmentId});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAppointmentDetails(widget.appointmentId);
    });
  }

  void _showCancelDialog() {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final appt = apptProvider.selectedAppointment;
    if (appt == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Cancel this appointment?',
            style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.',
            style: TextStyle(color: AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep appointment', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop(); // Close dialog

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final patientName = authProvider.currentUser?.fullName ?? 'Patient';

                final success = await apptProvider.updateStatus(
                  appointmentId: appt.id!,
                  status: 'cancelled',
                  notifyUserId: appt.doctor!.userId,
                  notificationTitle: 'Appointment Cancelled',
                  notificationBody: '$patientName has cancelled the appointment scheduled for ${appt.date} at ${appt.time}.',
                );

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Appointment cancelled.')),
                  );
                  navigator.pop(); // Go back to My Visits
                }
              },
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Visit Details'),
      ),
      body: apptProvider.isLoading || appt == null
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Appointment #${appt.id}',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              StatusPill(status: appt.status),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  AvatarInitials(name: appt.doctor?.user?.fullName ?? 'Doctor', radius: 28),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appt.doctor?.user?.fullName ?? 'Dr. Medical',
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${appt.doctor?.specialty ?? ''} • ${appt.doctor?.room ?? ''}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    Icons.calendar_today_outlined,
                                    'Date & Time',
                                    DateTimeUtils.formatDateAndSlot(appt.date, appt.time),
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    Icons.description_outlined,
                                    'Reason for Visit',
                                    appt.reason ?? 'General Consultation',
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    Icons.notifications_active_outlined,
                                    'Reminder',
                                    '30 minutes before',
                                  ),
                                  if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                                    const Divider(height: 24),
                                    _buildDetailRow(
                                      Icons.notes_outlined,
                                      'Doctor Notes',
                                      appt.notes!,
                                    ),
                                  ],
                                  if (appt.nextVisit != null && appt.nextVisit!.isNotEmpty) ...[
                                    const Divider(height: 24),
                                    _buildDetailRow(
                                      Icons.event_repeat_outlined,
                                      'Next Visit',
                                      'Recommended in ${appt.nextVisit}',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (apptProvider.selectedPrescriptions.isNotEmpty) ...[
                            const Text(
                              'Prescriptions',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: apptProvider.selectedPrescriptions
                                      .map(
                                        (p) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.medication_outlined, color: AppColors.blue, size: 20),
                                              const SizedBox(width: 10),
                                              Text(
                                                p.medicine,
                                                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (appt.status == 'pending' || appt.status == 'confirmed')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border(top: BorderSide(color: AppColors.line)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Reschedule',
                              isSecondary: true,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.bookAppointment,
                                  arguments: {
                                    'doctorId': appt.doctorId,
                                    'rescheduleAppointmentId': appt.id,
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: 'Cancel',
                              isDanger: true,
                              onPressed: _showCancelDialog,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
