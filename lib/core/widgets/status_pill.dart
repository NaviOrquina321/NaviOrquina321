import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = status.replaceAll('_', ' ').toLowerCase();
    final displayLabel = formatted[0].toUpperCase() + formatted.substring(1);

    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppColors.pendingBg;
        textColor = AppColors.pendingText;
        break;
      case 'confirmed':
        bgColor = AppColors.confirmedBg;
        textColor = AppColors.confirmedText;
        break;
      case 'in_progress':
        bgColor = AppColors.inProgressBg;
        textColor = AppColors.inProgressText;
        break;
      case 'completed':
        bgColor = AppColors.completedBg;
        textColor = AppColors.completedText;
        break;
      case 'cancelled':
      case 'declined':
        bgColor = AppColors.cancelledBg;
        textColor = AppColors.cancelledText;
        break;
      default:
        bgColor = AppColors.tint;
        textColor = AppColors.navy;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
