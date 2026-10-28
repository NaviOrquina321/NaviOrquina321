import 'package:flutter/material.dart';
import 'core/constants/route_names.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/doctor/doctor_availability_screen.dart';
import 'screens/doctor/doctor_consultation_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/doctor/doctor_patients_screen.dart';
import 'screens/doctor/doctor_profile_account_screen.dart';
import 'screens/doctor/doctor_reviews_screen.dart';
import 'screens/doctor/patient_details_screen.dart';
import 'screens/doctor/pin_clinic_screen.dart';
import 'screens/onboarding/doctor_onboarding_screen.dart';
import 'screens/onboarding/patient_onboarding_screen.dart';
import 'screens/patient/book_appointment_screen.dart';
import 'screens/patient/booking_confirmed_screen.dart';
import 'screens/patient/doctor_profile_screen.dart';
import 'screens/patient/home_screen.dart';
import 'screens/patient/my_visits_screen.dart';
import 'screens/patient/patient_doctors_screen.dart';
import 'screens/patient/patient_profile_screen.dart';
import 'screens/patient/rate_visit_screen.dart';
import 'screens/patient/reminders_screen.dart';
import 'screens/patient/medical_records_screen.dart';
import 'screens/patient/payment_screen.dart';
import 'screens/patient/visit_details_screen.dart';
import 'screens/patient/visit_summary_screen.dart';
import 'screens/shared/appointment_chat_screen.dart';
import 'screens/shared/clinic_details_screen.dart';
import 'screens/shared/help_support_screen.dart';
import 'screens/shared/offline_state_screen.dart';
import 'screens/shared/report_problem_screen.dart';
import 'screens/shared/settings_screen.dart';
import 'screens/shared/support_chat_screen.dart';
import 'screens/shared/video_call_screen.dart';
import 'screens/signup/signup_wizard_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case RouteNames.login:
        final args = settings.arguments as Map<String, dynamic>?;
        final isPatient = args != null && args['role'] == 'doctor' ? false : true;
        return MaterialPageRoute(builder: (_) => LoginScreen(initialIsPatient: isPatient));
      case RouteNames.register:
      case RouteNames.signupWizard:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialRole = args != null && args['role'] == 'doctor' ? 'doctor' : 'patient';
        return MaterialPageRoute(builder: (_) => SignupWizardScreen(initialRole: initialRole));
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      // Onboarding Routes
      case RouteNames.patientOnboarding:
        return MaterialPageRoute(builder: (_) => const PatientOnboardingScreen());
      case RouteNames.doctorOnboarding:
        return MaterialPageRoute(builder: (_) => const DoctorOnboardingScreen());

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
      case RouteNames.payment:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => PaymentScreen(appointmentId: apptId));
      case RouteNames.visitSummary:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => VisitSummaryScreen(appointmentId: apptId));
      case RouteNames.medicalRecords:
        return MaterialPageRoute(builder: (_) => const MedicalRecordsScreen());

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
      case RouteNames.doctorReviews:
        final docId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => DoctorReviewsScreen(doctorId: docId));
      case RouteNames.patientDetails:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => PatientDetailsScreen(appointmentId: apptId));
      case RouteNames.pinClinic:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => PinClinicScreen(
              initialLat: args['lat'] as double?,
              initialLng: args['lng'] as double?,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const PinClinicScreen());

      // Shared Routes
      case RouteNames.helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());
      case RouteNames.supportChat:
        return MaterialPageRoute(builder: (_) => const SupportChatScreen());
      case RouteNames.reportProblem:
        return MaterialPageRoute(builder: (_) => const ReportProblemScreen());
      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case RouteNames.videoCall:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => VideoCallScreen(appointmentId: apptId));
      case RouteNames.appointmentChat:
        final apptId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => AppointmentChatScreen(appointmentId: apptId));
      case RouteNames.clinicLocation:
        final docId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => ClinicDetailsScreen(doctorId: docId));
      case RouteNames.offlineState:
        return MaterialPageRoute(builder: (_) => const OfflineStateScreen());

      default:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
    }
  }
}
