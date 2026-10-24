import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/status_pill.dart';
import '../../providers/appointment_provider.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final int appointmentId;

  const DoctorConsultationScreen({super.key, required this.appointmentId});

  @override
  State<DoctorConsultationScreen> createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  final _notesController = TextEditingController();
  final List<String> _medicines = [];
  String _nextVisitRecommendation = 'None';

  final List<String> _nextVisitOptions = ['None', '1 week', '1 month'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAppointmentDetails(widget.appointmentId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showAddMedicineDialog() {
    final medController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Medicine', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
          content: AppTextField(
            label: 'Medicine Name & Dosage',
            hint: 'e.g. Amoxicillin 500mg 3x daily',
            controller: medController,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (medController.text.trim().isNotEmpty) {
                  setState(() {
                    _medicines.add(medController.text.trim());
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCompleteVisit() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await apptProvider.completeConsultation(
      appointmentId: widget.appointmentId,
      notes: _notesController.text.trim(),
      medicines: _medicines,
      nextVisit: _nextVisitRecommendation == 'None' ? null : _nextVisitRecommendation,
    );

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Consultation completed successfully!')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to complete consultation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation'),
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
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  AvatarInitials(
                                    name: appt.patientUser?.fullName ?? 'Patient',
                                    radius: 24,
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
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Reason: ${appt.reason ?? 'General Consultation'}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const StatusPill(status: 'in_progress'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Visit Notes',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter clinical observations, diagnosis...',
                              fillColor: AppColors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Prescription',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showAddMedicineDialog,
                                icon: const Icon(Icons.add, size: 18, color: AppColors.blue),
                                label: const Text('Add medicine', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_medicines.isEmpty)
                            const Text(
                              'No medicines added yet.',
                              style: TextStyle(color: AppColors.muted, fontSize: 13),
                            )
                          else
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: _medicines
                                      .map(
                                        (med) => ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.medication_outlined, color: AppColors.blue),
                                          title: Text(med, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                                            onPressed: () {
                                              setState(() {
                                                _medicines.remove(med);
                                              });
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          const Text(
                            'Recommend Next Visit',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: _nextVisitOptions.map((opt) {
                              final isSelected = _nextVisitRecommendation == opt;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: AppChip(
                                  label: opt,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _nextVisitRecommendation = opt;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
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
                      text: 'Complete visit',
                      isLoading: apptProvider.isLoading,
                      onPressed: _handleCompleteVisit,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
