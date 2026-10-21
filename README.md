# Doctor Appointment App

A production-quality Flutter application for scheduling doctor appointments and managing consultations using SQLite for offline-first local data persistence.

## Features & Implementation
- **Material 3 Design System**: DM Sans typography (`google_fonts`), custom AppColors theme, full semantic button labels, text scaling, and 44x44 minimum tap targets.
- **SQLite Database**: Local DB version 1 with foreign keys enabled, salted SHA-256 password hashing, transactions for writes, and a partial unique index on `appointments(doctor_id, date, time)` for double booking prevention.
- **Patient & Doctor Portals**: Role-based access control and persistent session handling (`app_session` table).
  - **Patient**: Home, Search & Filter Doctors, Doctor Profile, 3-Step Appointment Booking, Booking Confirmed, My Visits (Upcoming/Past), Visit Details, Cancel Confirmation, Rate Your Visit, Reminders, and Patient Profile.
  - **Doctor**: Schedule Dashboard, Patients Search & Filter, Working Hours / Availability Management, Profile & Auto-Confirm Switch, and Consultation (Notes, Prescriptions, Next Visit recommendation).

## Test Accounts
All test accounts use the password: `Password123`

- **Patient**: `louie@email.com` / `Password123`
- **Doctor 1 (Cardiologist)**: `rj@clinic.com` / `Password123`
- **Doctor 2 (Pediatrician)**: `ivan@clinic.com` / `Password123`
- **Doctor 3 (Dermatologist)**: `alejo@clinic.com` / `Password123`

## Project Structure
```
lib/
  main.dart
  routes.dart
  core/
    constants/
    theme/ (AppColors, AppTheme)
    utils/ (DateTimeUtils, Validators)
    widgets/ (AppButton, AppTextField, AppChip, DoctorCard, AppointmentCard, etc.)
  data/
    db/ (database_helper.dart)
    models/ (models.dart - User, Doctor, Availability, Appointment, Prescription, Review, AppNotification)
    repositories/ (AuthRepository, DoctorRepository, AvailabilityRepository, AppointmentRepository, ReviewRepository, NotificationRepository)
  providers/ (AuthProvider, DoctorProvider, AvailabilityProvider, AppointmentProvider, NotificationProvider)
  screens/
    auth/ (Welcome, Login, Register, Forgot Password)
    patient/ (Home, Patient Doctors, Doctor Profile, Book Appointment, Booking Confirmed, My Visits, Visit Details, Rate Visit, Reminders, Patient Profile)
    doctor/ (Doctor Dashboard, Doctor Patients, Doctor Availability, Doctor Profile Account, Doctor Consultation)
test/
  unit_test.dart
```

## Running the App

### Requirements
- Flutter SDK `^3.11.0`
- Dart SDK `^3.11.0`

### Desktop Platform Note (Windows & Linux)
Running on Windows or Linux requires the `sqlite3` native C library installed on your platform so `sqflite_common_ffi` can connect to SQLite:
- **Windows**: Place `sqlite3.dll` in your build binary folder or system PATH.
- **Linux**: Install `libsqlite3-dev` (`sudo apt install libsqlite3-dev`).

### Run Commands
```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test -r expanded

# Launch app
flutter run
```
