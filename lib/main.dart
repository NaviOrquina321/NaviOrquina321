import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'data/db/database_helper.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/availability_repository.dart';
import 'data/repositories/doctor_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/availability_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/notification_provider.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop FFI initialization
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Ensure DB initialized
  await DatabaseHelper.instance.database;

  runApp(const DoctorAppointmentApp());
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
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasSession = await authProvider.tryAutoLogin();

    if (!mounted) return;

    if (hasSession && authProvider.currentUser != null) {
      if (authProvider.isDoctor) {
        Navigator.pushReplacementNamed(context, '/doctor/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/patient/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
