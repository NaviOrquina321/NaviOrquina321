import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Today', 'Follow-up'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  void _loadPatients() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      final docProvider = Provider.of<DoctorProvider>(context, listen: false);
      docProvider.fetchDoctorProfileForUser(userId).then((_) {
        final doc = docProvider.currentDoctorProfile;
        if (doc != null && mounted) {
          final dateFilter = _selectedFilter == 'Today' ? DateTimeUtils.formatSqlDate(DateTime.now()) : null;
          Provider.of<AppointmentProvider>(context, listen: false).fetchDoctorAppointments(
            doc.id!,
            dateFilter: dateFilter,
            filterType: _selectedFilter,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appointments = apptProvider.doctorAppointments;

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredAppointments = appointments.where((a) {
      final pName = a.patientUser?.fullName.toLowerCase() ?? '';
      final pReason = a.reason?.toLowerCase() ?? '';
      return pName.contains(searchQuery) || pReason.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Patients'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search patient or reason...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  fillColor: AppColors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return AppChip(
                    label: filter,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _loadPatients();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadPatients(),
                child: apptProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredAppointments.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.5,
                              alignment: Alignment.center,
                              child: const EmptyState(
                                icon: Icons.people_outline,
                                title: 'No Patients Found',
                                description: 'No patient visits match your search criteria.',
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredAppointments.length,
                            itemBuilder: (context, index) {
                              final appt = filteredAppointments[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: AvatarInitials(
                                    name: appt.patientUser?.fullName ?? 'Patient',
                                    radius: 24,
                                  ),
                                  title: Text(
                                    appt.patientUser?.fullName ?? 'Patient',
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Last visit: ${appt.reason ?? 'General'}',
                                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateTimeUtils.formatDateAndSlot(appt.date, appt.time),
                                        style: const TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.doctorConsultation,
                                      arguments: appt.id,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DoctorBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorDashboard);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorAvailability);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorProfileAccount);
          }
        },
      ),
    );
  }
}
