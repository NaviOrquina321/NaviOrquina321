import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';

class PinClinicScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const PinClinicScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<PinClinicScreen> createState() => _PinClinicScreenState();
}

class _PinClinicScreenState extends State<PinClinicScreen> {
  late LatLng _currentPin;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentPin = LatLng(
      widget.initialLat ?? 14.5995,
      widget.initialLng ?? 120.9842,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pin Clinic Location'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPin,
              initialZoom: 16.0,
              onTap: (_, point) {
                setState(() {
                  _currentPin = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.doctorappointment.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPin,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.danger,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Text(
                'Tap anywhere on the map to place your clinic pin.\nLat: ${_currentPin.latitude.toStringAsFixed(5)}, Lng: ${_currentPin.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12, color: AppColors.navy),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: PrimaryButton(
              text: 'Confirm Location',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () {
                Navigator.pop(context, _currentPin);
              },
            ),
          ),
        ],
      ),
    );
  }
}
