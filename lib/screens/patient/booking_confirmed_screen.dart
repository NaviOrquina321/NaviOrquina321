import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../providers/appointment_provider.dart';

class BookingConfirmedScreen extends StatefulWidget {
  final int appointmentId;

  const BookingConfirmedScreen({super.key, required this.appointmentId});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAppointmentDetails(widget.appointmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;

    final isConfirmed = appt?.status == 'confirmed';
    final headline = isConfirmed ? 'Appointment Confirmed!' : 'Request Sent!';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: 90,
                width: 90,
                decoration: const BoxDecoration(
                  color: AppColors.tint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.blue,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                headline,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isConfirmed
                    ? 'Your appointment has been successfully scheduled.'
                    : 'Your request has been sent to the doctor for review.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              if (appt != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Doctor', style: TextStyle(color: AppColors.muted)),
                            Text(
                              appt.doctor?.user?.fullName ?? 'Doctor',
                              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Specialty', style: TextStyle(color: AppColors.muted)),
                            Text(
                              appt.doctor?.specialty ?? '',
                              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Date & Time', style: TextStyle(color: AppColors.muted)),
                            Text(
                              DateTimeUtils.formatDateAndSlot(appt.date, appt.time),
                              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              AppButton(
                text: 'Add to calendar',
                isSecondary: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to calendar placeholder.')),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Back to home',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.patientHome,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
