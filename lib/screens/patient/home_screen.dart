import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/doctor_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _bottomNavIndex = 0;
  String _selectedSpecialty = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      Provider.of<DoctorProvider>(context, listen: false).fetchDoctors();
      Provider.of<DoctorProvider>(context, listen: false).fetchSpecialties();
      Provider.of<AppointmentProvider>(context, listen: false).fetchPatientAppointments(userId);
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: CustomScrollView(
            slivers: [
              // Header
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
                            const Text(
                              'Hello,',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              user?.fullName ?? 'Patient',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_outlined, size: 28, color: AppColors.navy),
                            onPressed: () {
                              Navigator.pushNamed(context, RouteNames.reminders);
                            },
                          ),
                          if (notificationProvider.unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '${notificationProvider.unreadCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      doctorProvider.fetchDoctors(
                        searchQuery: val,
                        specialty: _selectedSpecialty,
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Search doctor, specialty...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                      fillColor: AppColors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                ),
              ),

              // Upcoming Visit Banner
              if (appointmentProvider.nextUpcomingAppointment != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Upcoming Visit',
                                style: TextStyle(
                                  color: AppColors.tile,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.visitDetails,
                                    arguments: appointmentProvider.nextUpcomingAppointment!.id,
                                  );
                                },
                                child: const Text(
                                  'View details',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            appointmentProvider.nextUpcomingAppointment!.doctor?.user?.fullName ?? 'Doctor',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            appointmentProvider.nextUpcomingAppointment!.doctor?.specialty ?? '',
                            style: const TextStyle(
                              color: AppColors.tint,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.tile),
                              const SizedBox(width: 6),
                              Text(
                                DateTimeUtils.formatDateAndSlot(
                                  appointmentProvider.nextUpcomingAppointment!.date,
                                  appointmentProvider.nextUpcomingAppointment!.time,
                                ),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Specialties Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Specialty'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: doctorProvider.specialties.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final spec = doctorProvider.specialties[index];
                            final isSelected = spec == _selectedSpecialty;
                            return AppChip(
                              label: spec,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedSpecialty = spec;
                                });
                                doctorProvider.fetchDoctors(
                                  searchQuery: _searchController.text,
                                  specialty: spec,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Available Doctors Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SectionHeader(
                    title: 'Available Doctors',
                    actionText: 'See all',
                    onActionTap: () {
                      Navigator.pushNamed(context, RouteNames.patientDoctors);
                    },
                  ),
                ),
              ),

              // Doctor List
              if (doctorProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (doctorProvider.doctors.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No Doctors Found',
                    description: 'No available doctors match your criteria.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = doctorProvider.doctors[index];
                        return DoctorCard(
                          name: doc.user?.fullName ?? 'Dr. Medical',
                          specialty: doc.specialty ?? 'General Medicine',
                          rating: doc.rating,
                          nextSlot: 'Today 09:00 AM',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.doctorProfile,
                              arguments: doc.id,
                            );
                          },
                          onBookTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.bookAppointment,
                              arguments: doc.id,
                            );
                          },
                        );
                      },
                      childCount: doctorProvider.doctors.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PatientBottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushNamed(context, RouteNames.patientDoctors);
          } else if (index == 2) {
            Navigator.pushNamed(context, RouteNames.myVisits);
          } else if (index == 3) {
            Navigator.pushNamed(context, RouteNames.patientProfile);
          }
        },
      ),
    );
  }
}
