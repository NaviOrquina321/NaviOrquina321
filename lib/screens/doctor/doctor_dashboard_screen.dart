import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/models.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  void _loadDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      final docProvider = Provider.of<DoctorProvider>(context, listen: false);
      await docProvider.fetchDoctorProfileForUser(userId);

      final doc = docProvider.currentDoctorProfile;
      if (doc != null && mounted) {
        final todayStr = DateTimeUtils.formatSqlDate(DateTime.now());
        Provider.of<AppointmentProvider>(context, listen: false).fetchDoctorAppointments(
          doc.id!,
          dateFilter: todayStr,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final docProvider = Provider.of<DoctorProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);

    final doctorUser = authProvider.currentUser;
    final doctor = docProvider.currentDoctorProfile;
    final appointments = apptProvider.doctorAppointments;

    final todayCount = appointments.length;
    final pendingCount = appointments.where((a) => a.status == 'pending').length;
    final completedCount = appointments.where((a) => a.status == 'completed').length;

    final confirmedOrInProgress = appointments.where((a) => a.status == 'confirmed' || a.status == 'in_progress').toList();
    final Appointment? nextPatient = confirmedOrInProgress.isNotEmpty ? confirmedOrInProgress.first : null;
    final hasNextPatient = nextPatient != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadDashboard(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.tint,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/logo_mark.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.blue,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateTimeUtils.formatDate(DateTime.now()),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              doctorUser?.fullName ?? 'Doctor',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildSummaryTile('$todayCount', 'Today', AppColors.tint, AppColors.blue),
                      const SizedBox(width: 10),
                      _buildSummaryTile('$pendingCount', 'Pending', AppColors.pendingBg, AppColors.pendingText),
                      const SizedBox(width: 10),
                      _buildSummaryTile('$completedCount', 'Done', AppColors.completedBg, AppColors.completedText),
                    ],
                  ),
                ),
              ),

              if (hasNextPatient && doctor != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Patient',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AvatarInitials(
                                      name: nextPatient.patientUser?.fullName ?? 'Patient',
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nextPatient.patientUser?.fullName ?? 'Patient',
                                            style: const TextStyle(
                                              color: AppColors.navy,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            nextPatient.reason ?? 'General Consultation',
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusPill(status: nextPatient.status),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.blue),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateTimeUtils.formatTime(nextPatient.time),
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  text: 'Start consultation',
                                  onPressed: () async {
                                    final navigator = Navigator.of(context);
                                    if (nextPatient.status != 'in_progress') {
                                      await apptProvider.updateStatus(
                                        appointmentId: nextPatient.id!,
                                        status: 'in_progress',
                                        notifyUserId: nextPatient.patientId,
                                        notificationTitle: 'Consultation Started',
                                        notificationBody: '${doctorUser?.fullName ?? 'Your doctor'} has started your consultation.',
                                      );
                                    }
                                    navigator.pushNamed(
                                      RouteNames.doctorConsultation,
                                      arguments: nextPatient.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    'Later Today (${appointments.length})',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (apptProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (appointments.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No Visits Scheduled',
                    description: 'You have no appointments scheduled for today.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final appt = appointments[index];
                        final isPending = appt.status == 'pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AvatarInitials(
                                      name: appt.patientUser?.fullName ?? 'Patient',
                                      radius: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appt.patientUser?.fullName ?? 'Patient',
                                            style: const TextStyle(
                                              color: AppColors.navy,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${DateTimeUtils.formatTime(appt.time)} • ${appt.reason ?? 'General'}',
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusPill(status: appt.status),
                                  ],
                                ),
                                if (isPending) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SmallButton(
                                          text: 'Accept',
                                          variant: SmallButtonVariant.primary,
                                          onPressed: () async {
                                            await apptProvider.updateStatus(
                                              appointmentId: appt.id!,
                                              status: 'confirmed',
                                              notifyUserId: appt.patientId,
                                              notificationTitle: 'Request Accepted',
                                              notificationBody: 'Your appointment request for ${appt.date} at ${appt.time} was confirmed.',
                                            );
                                            _loadDashboard();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SmallButton(
                                          text: 'Decline',
                                          variant: SmallButtonVariant.dangerOutlined,
                                          onPressed: () async {
                                            await apptProvider.updateStatus(
                                              appointmentId: appt.id!,
                                              status: 'declined',
                                              notifyUserId: appt.patientId,
                                              notificationTitle: 'Request Declined',
                                              notificationBody: 'Your appointment request for ${appt.date} at ${appt.time} was declined.',
                                            );
                                            _loadDashboard();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: appointments.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DoctorBottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorPatients);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorAvailability);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorProfileAccount);
          }
        },
      ),
    );
  }

  Widget _buildSummaryTile(String value, String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
