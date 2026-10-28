import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../providers/appointment_provider.dart';

class VideoCallScreen extends StatefulWidget {
  final int appointmentId;

  const VideoCallScreen({super.key, required this.appointmentId});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMicOn = true;
  bool _isCameraOn = true;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMeetingLink();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _initMeetingLink() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    await apptProvider.fetchAppointmentDetails(widget.appointmentId);
    final appt = apptProvider.selectedAppointment;
    if (appt != null && (appt.meetingLink == null || appt.meetingLink!.isEmpty)) {
      final link = 'https://meet.jit.si/DoctorApp-${appt.id}-${DateTime.now().millisecondsSinceEpoch % 10000}';
      await apptProvider.saveMeetingLink(widget.appointmentId, link);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleJoinJitsi() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final appt = apptProvider.selectedAppointment;
    if (appt?.meetingLink != null && appt!.meetingLink!.isNotEmpty) {
      final Uri uri = Uri.parse(appt.meetingLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to launch video meeting link.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text(
              appt?.doctor?.user?.fullName ?? 'Video Consultation',
              style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _formatDuration(_secondsElapsed),
              style: const TextStyle(color: AppColors.tile, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Main Video Area
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AvatarInitials(
                          name: appt?.doctor?.user?.fullName ?? 'Doctor',
                          radius: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appt?.doctor?.user?.fullName ?? 'Dr. Medical',
                          style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          appt?.doctor?.specialty ?? 'General Practice',
                          style: const TextStyle(color: AppColors.tile, fontSize: 14),
                        ),
                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: AppButton(
                            text: 'Launch External Call Room',
                            icon: Icons.video_call_rounded,
                            onPressed: _handleJoinJitsi,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Small "You" panel
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      width: 100,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.blue, width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCameraOn ? Icons.person_rounded : Icons.videocam_off_rounded,
                              color: AppColors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'You',
                              style: TextStyle(color: AppColors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _isMicOn ? AppColors.navy : Colors.red,
                    child: IconButton(
                      icon: Icon(_isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded, color: AppColors.white),
                      onPressed: () {
                        setState(() {
                          _isMicOn = !_isMicOn;
                        });
                      },
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _isCameraOn ? AppColors.navy : Colors.red,
                    child: IconButton(
                      icon: Icon(_isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, color: AppColors.white),
                      onPressed: () {
                        setState(() {
                          _isCameraOn = !_isCameraOn;
                        });
                      },
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.navy,
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.white),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.supportChat,
                        );
                      },
                    ),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.danger,
                    child: IconButton(
                      icon: const Icon(Icons.call_end_rounded, color: AppColors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
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
