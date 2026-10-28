import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/doctor_provider.dart';

class PatientDetailsScreen extends StatefulWidget {
  final int appointmentId;

  const PatientDetailsScreen({super.key, required this.appointmentId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    await apptProvider.fetchAppointmentDetails(widget.appointmentId);
    if (!mounted) return;

    final appt = apptProvider.selectedAppointment;
    if (appt != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        final docProvider = Provider.of<DoctorProvider>(context, listen: false);
        await docProvider.fetchDoctorProfileForUser(userId);
        if (!mounted) return;

        final doc = docProvider.currentDoctorProfile;
        if (doc != null) {
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          await chatProvider.fetchPatientNote(doctorId: doc.id!, patientId: appt.patientId);
          if (!mounted) return;

          if (chatProvider.patientNote != null) {
            _noteController.text = chatProvider.patientNote!;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveNote() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final appt = apptProvider.selectedAppointment;
    if (appt == null) return;

    final docProvider = Provider.of<DoctorProvider>(context, listen: false);
    final doc = docProvider.currentDoctorProfile;
    if (doc == null) return;

    setState(() {
      _isSavingNote = true;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.savePatientNote(
      doctorId: doc.id!,
      patientId: appt.patientId,
      note: _noteController.text,
    );

    setState(() {
      _isSavingNote = false;
    });

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Private patient note saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;
    final patient = appt?.patientUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Details'),
      ),
      body: apptProvider.isLoading || appt == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            AvatarInitials(name: patient?.fullName ?? 'Patient', radius: 36),
                            const SizedBox(height: 12),
                            Text(
                              patient?.fullName ?? 'Patient Name',
                              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patient?.email ?? '',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    text: 'Chat',
                                    isSecondary: true,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.appointmentChat,
                                        arguments: appt.id,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    text: 'Consultation',
                                    icon: Icons.medical_services_outlined,
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.doctorConsultation,
                                        arguments: appt.id,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current Visit Summary Card
                    const Text(
                      'Current Appointment',
                      style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateTimeUtils.formatDateAndSlot(appt.date, appt.time)} (${appt.visitType})',
                              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Reason: ${appt.reason ?? "General checkup"}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Private Doctor Notes Section
                    const Text(
                      'Private Patient Notes',
                      style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Visible only to you for this patient.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _noteController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Enter private medical or visit notes for this patient...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: AppButton(
                                text: 'Save Note',
                                isLoading: _isSavingNote,
                                onPressed: _handleSaveNote,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
