import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';

import '../../data/repositories/review_repository.dart';
import '../../data/models/models.dart';
import '../../providers/doctor_provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  final int doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  List<Review> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).fetchDoctorDetails(widget.doctorId);
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    final reviewRepo = ReviewRepository();
    final list = await reviewRepo.getDoctorReviews(widget.doctorId);
    if (mounted) {
      setState(() {
        _reviews = list;
        _loadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final doc = doctorProvider.selectedDoctor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
      ),
      body: doctorProvider.isLoading || doc == null
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
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  AvatarInitials(
                                    name: doc.user?.fullName ?? 'Doctor',
                                    radius: 36,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.user?.fullName ?? 'Dr. Medical',
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${doc.specialty ?? 'General'} • ${doc.room ?? 'Room 1'}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              _buildStatTile('${doc.patientsCount}+', 'Patients'),
                              const SizedBox(width: 12),
                              _buildStatTile('${doc.yearsExperience} yrs', 'Experience'),
                              const SizedBox(width: 12),
                              _buildStatTile('${doc.rating}', 'Rating'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'About Doctor',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doc.bio ?? 'No biography provided.',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Reviews',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_loadingReviews)
                            const Center(child: CircularProgressIndicator())
                          else if (_reviews.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No reviews yet.',
                                style: TextStyle(color: AppColors.muted, fontSize: 14),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final rev = _reviews[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            AvatarInitials(
                                              name: rev.patientUser?.fullName ?? 'Patient',
                                              radius: 16,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                rev.patientUser?.fullName ?? 'Patient',
                                                style: const TextStyle(
                                                  color: AppColors.navy,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: List.generate(
                                                5,
                                                (starIdx) => Icon(
                                                  Icons.star_rounded,
                                                  size: 16,
                                                  color: starIdx < rev.rating
                                                      ? AppColors.star
                                                      : AppColors.line,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            rev.comment!,
                                            style: const TextStyle(
                                              color: AppColors.navy,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                    child: AppButton(
                      text: 'Book appointment',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.bookAppointment,
                          arguments: doc.id,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
