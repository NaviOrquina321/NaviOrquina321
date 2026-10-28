import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/constants/route_names.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_logo.dart';
import 'data/db/database_helper.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/availability_repository.dart';
import 'data/repositories/doctor_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/medical_record_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/support_repository.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/availability_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/medical_record_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/support_provider.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    runApp(const WebNotSupportedApp());
    return;
  }

  // Desktop FFI initialization
  if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Ensure DB initialized
  await DatabaseHelper.instance.database;

  runApp(const DoctorAppointmentApp());
}

class WebNotSupportedApp extends StatelessWidget {
  const WebNotSupportedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F8FD),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.phonelink_off, size: 64, color: Color(0xFF1565C0)),
                SizedBox(height: 16),
                Text(
                  'Web Platform Not Supported',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B3470)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'This app uses native SQLite (sqflite).\n\nPlease run the application on Android, iOS, or Desktop (Windows / macOS / Linux).\n\nExample command:\nflutter run -d windows (or macos / linux / android)',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4A5F7D)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DoctorAppointmentApp extends StatelessWidget {
  const DoctorAppointmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository: AuthRepository())),
        ChangeNotifierProvider(create: (_) => DoctorProvider(doctorRepository: DoctorRepository())),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider(availabilityRepository: AvailabilityRepository())),
        ChangeNotifierProvider(create: (_) => AppointmentProvider(appointmentRepository: AppointmentRepository())),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationRepository: NotificationRepository())),
        ChangeNotifierProvider(create: (_) => SupportProvider(supportRepository: SupportRepository())),
        ChangeNotifierProvider(create: (_) => SettingsProvider(settingsRepository: SettingsRepository())),
        ChangeNotifierProvider(create: (_) => MedicalRecordProvider(medicalRecordRepository: MedicalRecordRepository())),
        ChangeNotifierProvider(create: (_) => ChatProvider(chatRepository: ChatRepository())),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Doctor Appointment',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            onGenerateRoute: AppRoutes.generateRoute,
            home: const SplashOrHomeScreen(),
          );
        },
      ),
    );
  }
}

class SplashOrHomeScreen extends StatefulWidget {
  const SplashOrHomeScreen({super.key});

  @override
  State<SplashOrHomeScreen> createState() => _SplashOrHomeScreenState();
}

class _SplashOrHomeScreenState extends State<SplashOrHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasSession = await authProvider.tryAutoLogin();

    if (!mounted) return;

    if (hasSession && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      if (user.profileCompleted == 0) {
        if (authProvider.isDoctor) {
          Navigator.pushReplacementNamed(context, RouteNames.doctorOnboarding);
        } else {
          Navigator.pushReplacementNamed(context, RouteNames.patientOnboarding);
        }
      } else {
        if (authProvider.isDoctor) {
          Navigator.pushReplacementNamed(context, RouteNames.doctorDashboard);
        } else {
          Navigator.pushReplacementNamed(context, RouteNames.patientHome);
        }
      }
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            AppLogo(size: 100),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
