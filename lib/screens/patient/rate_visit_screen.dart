import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../data/repositories/review_repository.dart';
import '../../providers/appointment_provider.dart';

class RateVisitScreen extends StatefulWidget {
  final int appointmentId;

  const RateVisitScreen({super.key, required this.appointmentId});

  @override
  State<RateVisitScreen> createState() => _RateVisitScreenState();
}

class _RateVisitScreenState extends State<RateVisitScreen> {
  int _selectedRating = 5;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _availableTags = ['Friendly', 'On time', 'Clear advice', 'Great care', 'Clean clinic'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAppointmentDetails(widget.appointmentId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitReview() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final appt = apptProvider.selectedAppointment;
    if (appt == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final reviewRepo = ReviewRepository();
    await reviewRepo.submitReview(
      appointmentId: appt.id!,
      patientId: appt.patientId,
      doctorId: appt.doctorId,
      rating: _selectedRating,
      tags: _selectedTags.join(','),
      comment: _commentController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Your Visit'),
      ),
      body: apptProvider.isLoading || appt == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'How was your visit with ${appt.doctor?.user?.fullName ?? 'your doctor'}?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appt.doctor?.specialty ?? '',
                      style: const TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          iconSize: 40,
                          icon: Icon(
                            Icons.star_rounded,
                            color: starValue <= _selectedRating ? AppColors.star : AppColors.line,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What went well?',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return ChoiceChip(
                          label: Text(tag),
                          selected: isSelected,
                          selectedColor: AppColors.blue,
                          backgroundColor: AppColors.tint,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.white : AppColors.navy,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add an optional comment...',
                        fillColor: AppColors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    AppButton(
                      text: 'Submit review',
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmitReview,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
