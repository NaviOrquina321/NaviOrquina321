import 'package:flutter/material.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const AppLogo(size: 120),
              const SizedBox(height: 32),
              const Text(
                'Doctor Appointment',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Schedule appointments, manage patient visits, and access healthcare easily.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Get started',
                onPressed: () {
                  Navigator.pushNamed(context, RouteNames.register);
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'I already have an account',
                onPressed: () {
                  Navigator.pushNamed(context, RouteNames.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
