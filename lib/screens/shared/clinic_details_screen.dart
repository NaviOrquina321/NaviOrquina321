import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/clinic_map_card.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../services/location_service.dart';

class ClinicDetailsScreen extends StatefulWidget {
  final int doctorId;

  const ClinicDetailsScreen({super.key, required this.doctorId});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  StreamSubscription<Position>? _patientLocationSubscription;
  Position? _patientPosition;
  double? _distanceMeters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _startPatientLocationStream();
    });
  }

  @override
  void dispose() {
    _patientLocationSubscription?.cancel();
    super.dispose();
  }

  void _loadData() async {
    final docProvider = Provider.of<DoctorProvider>(context, listen: false);
    await docProvider.fetchDoctorDetails(widget.doctorId);
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null && user.role == 'patient') {
      final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await apptProvider.fetchPatientAppointments(user.id!, dateFilter: todayStr);
    }
  }

  void _startPatientLocationStream() async {
    final hasPermission = await LocationService.requestLocationPermission();
    if (!hasPermission) return;

    _patientLocationSubscription = LocationService.getPatientLocationStream().listen((pos) {
      if (mounted) {
        setState(() {
          _patientPosition = pos;
          _updateDistance();
        });
      }
    });
  }

  void _updateDistance() {
    final doctor = Provider.of<DoctorProvider>(context, listen: false).selectedDoctor;
    if (doctor != null && doctor.latitude != null && doctor.longitude != null && _patientPosition != null) {
      final meters = LocationService.calculateDistanceMeters(
        _patientPosition!.latitude,
        _patientPosition!.longitude,
        doctor.latitude!,
        doctor.longitude!,
      );
      setState(() {
        _distanceMeters = meters;
      });
    }
  }

  Future<void> _openExternalMaps(double lat, double lng, String address) async {
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($address)');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: address));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address copied to clipboard.')),
        );
      }
    }
  }

  void _shareClinicLocation(String name, String address, double? lat, double? lng) {
    final mapsLink = (lat != null && lng != null)
        ? 'https://maps.google.com/?q=$lat,$lng'
        : address;
    Share.share('Clinic Location for $name:\n$address\n$mapsLink');
  }

  void _handleArrived(int appointmentId, int doctorUserId) async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final patientName = authProvider.currentUser?.fullName ?? 'Patient';

    final nowIso = DateTime.now().toIso8601String();
    await apptProvider.markArrived(
      appointmentId: appointmentId,
      arrivedAt: nowIso,
      doctorUserId: doctorUserId,
      patientName: patientName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent to doctor: Patient has arrived!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DoctorProvider>(context);
    final doctor = docProvider.selectedDoctor;
    final authProvider = Provider.of<AuthProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);

    final clinicName = doctor?.clinicName ?? 'Clinic Location';
    final address = doctor?.clinicAddress ?? '123 Health Ave, Metro Manila';
    final lat = doctor?.latitude ?? 14.5995;
    final lng = doctor?.longitude ?? 120.9842;
    final phone = doctor?.clinicPhone ?? '+63 2 8123 4567';
    final verificationDate = doctor?.locationUpdatedAt;

    // Check if patient has a confirmed appointment today with this doctor
    final todayAppts = apptProvider.patientAppointments.where((a) =>
        a.doctorId == doctor?.id &&
        (a.status == 'confirmed' || a.status == 'in_progress') &&
        a.visitType == 'In person');

    final todayAppt = todayAppts.isNotEmpty ? todayAppts.first : null;
    final isWithin200m = _distanceMeters != null && _distanceMeters! <= 200;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinic Location'),
      ),
      body: docProvider.isLoading || doctor == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClinicMapCard(
                    latitude: lat,
                    longitude: lng,
                    patientLatitude: _patientPosition?.latitude,
                    patientLongitude: _patientPosition?.longitude,
                    clinicName: clinicName,
                    address: address,
                    height: 220,
                  ),
                  const SizedBox(height: 16),

                  if (_distanceMeters != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded, color: AppColors.blue, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${(_distanceMeters! / 1000).toStringAsFixed(1)} km away from you',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinicName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                          if (verificationDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Location verified by GPS on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(verificationDate))}',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(address, style: const TextStyle(color: AppColors.navy, fontSize: 14, height: 1.3)),
                              ),
                            ],
                          ),
                          if (doctor.directionsNote != null && doctor.directionsNote!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Directions: ${doctor.directionsNote!}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.line),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, color: AppColors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(phone, style: const TextStyle(color: AppColors.navy, fontSize: 14))),
                              TextButton.icon(
                                icon: const Icon(Icons.call, size: 16, color: AppColors.blue),
                                label: const Text('Call', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Arrived button for appointment today
                  if (authProvider.currentUser?.role == 'patient' && todayAppt != null && isWithin200m) ...[
                    PrimaryButton(
                      text: todayAppt.arrivedAt != null ? "You've Arrived" : "I've arrived at the clinic",
                      icon: Icons.check_circle_rounded,
                      onPressed: todayAppt.arrivedAt != null
                          ? null
                          : () => _handleArrived(todayAppt.id!, doctor.userId),
                    ),
                    const SizedBox(height: 12),
                  ],

                  PrimaryButton(
                    text: 'Open in Maps app',
                    icon: Icons.directions_outlined,
                    onPressed: () => _openExternalMaps(lat, lng, address),
                  ),
                  const SizedBox(height: 12),

                  SecondaryButton(
                    text: 'Share location',
                    icon: Icons.share_outlined,
                    onPressed: () => _shareClinicLocation(clinicName, address, lat, lng),
                  ),
                ],
              ),
            ),
    );
  }
}
