import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/status_pill.dart';
import '../../providers/appointment_provider.dart';

class VisitSummaryScreen extends StatefulWidget {
  final int appointmentId;

  const VisitSummaryScreen({super.key, required this.appointmentId});

  @override
  State<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends State<VisitSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAppointmentDetails(widget.appointmentId);
    });
  }

  Future<void> _handleDownloadPdf() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final appt = apptProvider.selectedAppointment;
    final prescriptions = apptProvider.selectedPrescriptions;
    if (appt == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Visit Summary & Prescription', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Doctor: ${appt.doctor?.user?.fullName ?? "Doctor"} (${appt.doctor?.specialty ?? "Specialist"})'),
              pw.Text('Patient: ${appt.patientUser?.fullName ?? "Patient"}'),
              pw.Text('Date: ${DateTimeUtils.formatDateAndSlot(appt.date, appt.time)}'),
              pw.Text('Status: ${appt.status.toUpperCase()}'),
              pw.SizedBox(height: 20),
              pw.Text('Doctor Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text(appt.notes ?? 'No notes recorded.'),
              pw.SizedBox(height: 20),
              pw.Text('Prescribed Medicines:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              if (prescriptions.isEmpty)
                pw.Text('No prescriptions issued.')
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: prescriptions.map((p) => pw.Bullet(text: p.medicine)).toList(),
                ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'visit_summary_${appt.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;
    final prescriptions = apptProvider.selectedPrescriptions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Visit summary'),
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
                          // Doctor summary card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  AvatarInitials(name: appt.doctor?.user?.fullName ?? 'Doctor', radius: 26),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appt.doctor?.user?.fullName ?? 'Dr. Medical',
                                          style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${appt.date} • ${appt.visitType}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusPill(status: appt.status),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Doctor's Notes
                          const Text(
                            'Doctor\'s notes',
                            style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                appt.notes ?? 'No doctor notes recorded for this visit.',
                                style: const TextStyle(color: AppColors.navy, fontSize: 14, height: 1.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Prescription
                          const Text(
                            'Prescription',
                            style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: prescriptions.isEmpty
                                  ? const Text('No prescriptions issued.', style: TextStyle(color: AppColors.muted))
                                  : Column(
                                      children: prescriptions.map((p) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Row(
                                            children: [
                                              const CircleAvatar(
                                                radius: 16,
                                                backgroundColor: AppColors.tint,
                                                child: Icon(Icons.medication_outlined, color: AppColors.blue, size: 18),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  p.medicine,
                                                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Follow-up Card
                          if (appt.nextVisit != null && appt.nextVisit!.isNotEmpty)
                            Card(
                              color: AppColors.tint,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_repeat_rounded, color: AppColors.blue),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Follow-up in ${appt.nextVisit}',
                                        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          RouteNames.bookAppointment,
                                          arguments: appt.doctorId,
                                        );
                                      },
                                      child: const Text('Book', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Fixed Bottom Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          text: 'Download PDF',
                          isSecondary: true,
                          icon: Icons.picture_as_pdf_outlined,
                          onPressed: _handleDownloadPdf,
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          text: 'Rate this visit',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.rateVisit,
                              arguments: appt.id,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
