import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../providers/doctor_provider.dart';

class ClinicLocationScreen extends StatefulWidget {
  final int? doctorId;

  const ClinicLocationScreen({super.key, this.doctorId});

  @override
  State<ClinicLocationScreen> createState() => _ClinicLocationScreenState();
}

class _ClinicLocationScreenState extends State<ClinicLocationScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.doctorId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final docProvider = Provider.of<DoctorProvider>(context, listen: false);
        docProvider.fetchDoctorDetails(widget.doctorId!);
      });
    }
  }

  Future<void> _openMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external maps app.')),
        );
      }
    }
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DoctorProvider>(context);
    final doctor = widget.doctorId != null ? docProvider.selectedDoctor : null;

    final roomInfo = doctor?.room != null ? ' (Room ${doctor!.room})' : '';
    final clinicName = 'Central Health Clinic$roomInfo';
    const address = '123 Medical Center Way, Suite 400, Healthcare District, Metro Manila';
    const hours = 'Mon - Fri: 8:00 AM - 5:00 PM\nSat: 8:00 AM - 12:00 PM\nSun: Closed';
    const phone = '+63 2 8123 4567';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinic Location'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map illustration card
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.map_rounded, size: 64, color: AppColors.tile),
                      SizedBox(height: 8),
                      Text('Interactive Map View', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Click "Open in Maps" below to navigate', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Chip(
                      avatar: const Icon(Icons.location_on, size: 16, color: AppColors.blue),
                      label: const Text('Clinic Map', style: TextStyle(fontSize: 12, color: AppColors.navy)),
                      backgroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Address details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinicName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.location_on_outlined, color: AppColors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(color: AppColors.navy, fontSize: 14, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.line),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.access_time_rounded, color: AppColors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hours,
                          style: TextStyle(color: AppColors.navy, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.line),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: AppColors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phone,
                          style: const TextStyle(color: AppColors.navy, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: AppColors.blue),
                        onPressed: () async {
                          final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            AppButton(
              text: 'Open in Maps app',
              icon: Icons.directions_outlined,
              onPressed: () => _openMaps(address),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.copy_rounded, color: AppColors.navy, size: 18),
              label: const Text('Copy address to clipboard', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
              onPressed: () => _copyAddress(address),
            ),
          ],
        ),
      ),
    );
  }
}
