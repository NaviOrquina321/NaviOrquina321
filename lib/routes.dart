import 'package:flutter/material.dart';
import 'core/constants/route_names.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/doctor/doctor_availability_screen.dart';
import 'screens/doctor/doctor_consultation_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/doctor/doctor_patients_screen.dart';
import 'screens/doctor/doctor_profile_account_screen.dart';
import 'screens/patient/book_appointment_screen.dart';
import 'screens/patient/booking_confirmed_screen.dart';
import 'screens/patient/doctor_profile_screen.dart';
import 'screens/patient/home_screen.dart';
import 'screens/patient/my_visits_screen.dart';
import 'screens/patient/patient_doctors_screen.dart';
import 'screens/patient/patient_profile_screen.dart';
import 'screens/patient/rate_visit_screen.dart';
import 'screens/patient/reminders_screen.dart';
import 'screens/patient/visit_details_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      // Patient Routes
      case RouteNames.patientHome:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.patientDoctors:
        return MaterialPageRoute(builder: (_) => const PatientDoctorsScreen());
      case RouteNames.doctorProfile:
        final docId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctorId: docId));
      case RouteNames.bookAppointment:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => BookAppointmentScreen(
              doctorId: args['doctorId'] as int,
              rescheduleAppointmentId: args['rescheduleAppointmentId'] as int?,
            ),
          );
        } else {
          final docId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctorId: docId));
        }
      case RouteNames.bookingConfirmed:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => BookingConfirmedScreen(appointmentId: apptId));
      case RouteNames.myVisits:
        return MaterialPageRoute(builder: (_) => const MyVisitsScreen());
      case RouteNames.visitDetails:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => VisitDetailsScreen(appointmentId: apptId));
      case RouteNames.rateVisit:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => RateVisitScreen(appointmentId: apptId));
      case RouteNames.reminders:
        return MaterialPageRoute(builder: (_) => const RemindersScreen());
      case RouteNames.patientProfile:
        return MaterialPageRoute(builder: (_) => const PatientProfileScreen());

      // Doctor Routes
      case RouteNames.doctorDashboard:
        return MaterialPageRoute(builder: (_) => const DoctorDashboardScreen());
      case RouteNames.doctorPatients:
        return MaterialPageRoute(builder: (_) => const DoctorPatientsScreen());
      case RouteNames.doctorAvailability:
        return MaterialPageRoute(builder: (_) => const DoctorAvailabilityScreen());
      case RouteNames.doctorProfileAccount:
        return MaterialPageRoute(builder: (_) => const DoctorProfileAccountScreen());
      case RouteNames.doctorConsultation:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => DoctorConsultationScreen(appointmentId: apptId));

      default:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
    }
  }
}
