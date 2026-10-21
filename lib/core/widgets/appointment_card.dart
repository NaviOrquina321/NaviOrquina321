import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/app_utils.dart';
import 'avatar_initials.dart';
import 'status_pill.dart';

class AppointmentCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onRescheduleTap;
  final VoidCallback? onCancelTap;
  final VoidCallback? onRateTap;

  const AppointmentCard({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    required this.onTap,
    this.onRescheduleTap,
    this.onCancelTap,
    this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDateTime = DateTimeUtils.formatDateAndSlot(date, time);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarInitials(name: doctorName, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Text(
                      formattedDateTime,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRescheduleTap != null || onCancelTap != null || onRateTap != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onRescheduleTap != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRescheduleTap,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Reschedule', style: TextStyle(color: AppColors.blue)),
                        ),
                      ),
                    if (onRescheduleTap != null && onCancelTap != null)
                      const SizedBox(width: 8),
                    if (onCancelTap != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancelTap,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.danger)),
                        ),
                      ),
                    if (onRateTap != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onRateTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Rate Visit', style: TextStyle(color: AppColors.white)),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
