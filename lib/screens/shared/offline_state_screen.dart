import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';

class OfflineStateScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflineStateScreen({super.key, this.onRetry});

  @override
  State<OfflineStateScreen> createState() => _OfflineStateScreenState();
}

class _OfflineStateScreenState extends State<OfflineStateScreen> {
  bool _isChecking = false;

  Future<void> _handleRetry() async {
    setState(() {
      _isChecking = true;
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isChecking = false;
    });

    if (!connectivityResult.contains(ConnectivityResult.none)) {
      if (widget.onRetry != null) {
        widget.onRetry!();
      } else if (mounted) {
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still offline. Please check your network connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                height: 120,
                width: 120,
                decoration: const BoxDecoration(
                  color: AppColors.tint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'You are offline',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Internet connection is required for online video calls and maps. Your offline appointment records and schedule remain fully accessible.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                text: 'Try again',
                isLoading: _isChecking,
                onPressed: _handleRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
