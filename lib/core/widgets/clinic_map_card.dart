import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

class ClinicMapCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double? patientLatitude;
  final double? patientLongitude;
  final String clinicName;
  final String? address;
  final double height;
  final bool interactive;
  final Function(LatLng point)? onTap;

  const ClinicMapCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.patientLatitude,
    this.patientLongitude,
    required this.clinicName,
    this.address,
    this.height = 200,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<ClinicMapCard> createState() => _ClinicMapCardState();
}

class _ClinicMapCardState extends State<ClinicMapCard> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = connectivity.contains(ConnectivityResult.none);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return Container(
        height: widget.height,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.muted),
            const SizedBox(height: 8),
            const Text(
              'You are offline',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              widget.address ?? 'Map tiles require internet connection.',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final clinicCenter = LatLng(widget.latitude, widget.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: clinicCenter,
            initialZoom: 15.0,
            interactionOptions: InteractionOptions(
              flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
            onTap: widget.onTap != null ? (_, point) => widget.onTap!(point) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.doctorappointment.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: clinicCenter,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                ),
                if (widget.patientLatitude != null && widget.patientLongitude != null)
                  Marker(
                    point: LatLng(widget.patientLatitude!, widget.patientLongitude!),
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
