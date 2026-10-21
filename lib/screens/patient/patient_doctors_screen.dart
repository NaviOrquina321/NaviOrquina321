import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/doctor_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/doctor_provider.dart';

class PatientDoctorsScreen extends StatefulWidget {
  const PatientDoctorsScreen({super.key});

  @override
  State<PatientDoctorsScreen> createState() => _PatientDoctorsScreenState();
}

class _PatientDoctorsScreenState extends State<PatientDoctorsScreen> {
  String _selectedSpecialty = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = Provider.of<DoctorProvider>(context, listen: false);
      docProvider.fetchDoctors();
      docProvider.fetchSpecialties();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Doctors'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  doctorProvider.fetchDoctors(
                    searchQuery: val,
                    specialty: _selectedSpecialty,
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search doctor or specialty...',
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
            const SizedBox(height: 16),
            Expanded(
              child: doctorProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : doctorProvider.doctors.isEmpty
                      ? const EmptyState(
                          title: 'No Doctors Found',
                          description: 'Try adjusting your search query or filter.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: doctorProvider.doctors.length,
                          itemBuilder: (context, index) {
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
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PatientBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, RouteNames.patientHome);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, RouteNames.myVisits);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, RouteNames.patientProfile);
          }
        },
      ),
    );
  }
}
