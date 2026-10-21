import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/appointment_card.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/review_repository.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';

class MyVisitsScreen extends StatefulWidget {
  const MyVisitsScreen({super.key});

  @override
  State<MyVisitsScreen> createState() => _MyVisitsScreenState();
}

class _MyVisitsScreenState extends State<MyVisitsScreen> {
  bool _showPast = false;
  final Map<int, bool> _reviewedMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVisits();
    });
  }

  void _loadVisits() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
      await apptProvider.fetchPatientAppointments(userId);

      final reviewRepo = ReviewRepository();
      for (final appt in apptProvider.pastAppointments) {
        if (appt.id != null && appt.status == 'completed') {
          final isRev = await reviewRepo.isAppointmentReviewed(appt.id!);
          if (mounted) {
            setState(() {
              _reviewedMap[appt.id!] = isRev;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final list = _showPast ? apptProvider.pastAppointments : apptProvider.upcomingAppointments;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Visits'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPast = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_showPast ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: !_showPast ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                          ),
                          child: Text(
                            'Upcoming',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: !_showPast ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPast = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showPast ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _showPast ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                          ),
                          child: Text(
                            'Past Visits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: _showPast ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: apptProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? EmptyState(
                          title: _showPast ? 'No Past Visits' : 'No Upcoming Visits',
                          description: _showPast
                              ? 'You have not completed any medical visits yet.'
                              : 'You have no scheduled medical appointments.',
                          buttonText: 'Book appointment',
                          onButtonPressed: () {
                            Navigator.pushNamed(context, RouteNames.patientDoctors);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final appt = list[index];
                            final isCompleted = appt.status == 'completed';
                            final isReviewed = appt.id != null && (_reviewedMap[appt.id!] ?? false);

                            return AppointmentCard(
                              doctorName: appt.doctor?.user?.fullName ?? 'Dr. Medical',
                              specialty: appt.doctor?.specialty ?? 'General',
                              date: appt.date,
                              time: appt.time,
                              status: appt.status,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.visitDetails,
                                  arguments: appt.id,
                                );
                              },
                              onRescheduleTap: !_showPast && (appt.status == 'confirmed' || appt.status == 'pending')
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.bookAppointment,
                                        arguments: {
                                          'doctorId': appt.doctorId,
                                          'rescheduleAppointmentId': appt.id,
                                        },
                                      );
                                    }
                                  : null,
                              onCancelTap: !_showPast && (appt.status == 'confirmed' || appt.status == 'pending')
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.visitDetails,
                                        arguments: appt.id,
                                      );
                                    }
                                  : null,
                              onRateTap: _showPast && isCompleted && !isReviewed
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.rateVisit,
                                        arguments: appt.id,
                                      ).then((_) => _loadVisits());
                                    }
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PatientBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, RouteNames.patientHome);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, RouteNames.patientDoctors);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, RouteNames.patientProfile);
          }
        },
      ),
    );
  }
}
