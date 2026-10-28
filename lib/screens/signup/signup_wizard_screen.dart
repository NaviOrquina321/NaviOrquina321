import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/clinic_map_card.dart';
import '../../core/widgets/step_progress_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/location_service.dart';

class SignupWizardScreen extends StatefulWidget {
  final String initialRole;

  const SignupWizardScreen({super.key, this.initialRole = 'patient'});

  @override
  State<SignupWizardScreen> createState() => _SignupWizardScreenState();
}

class _SignupWizardScreenState extends State<SignupWizardScreen> {
  int _currentStep = 1;
  late String _role;
  bool _accountCreated = false;

  // Step 1 Account Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final bool _obscurePassword = true;

  // Personal Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  DateTime? _dob;
  final String _sex = 'Male';
  final _phoneController = TextEditingController();
  String? _photoPath;

  // Patient Medical
  String _bloodType = 'O+';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final Set<String> _allergies = {'Penicillin'};
  final _customAllergyController = TextEditingController();
  final Set<String> _conditions = {};
  final List<String> _medications = [];
  final _medicationController = TextEditingController();
  final _philhealthController = TextEditingController();

  // Contact/Address
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Doctor Professional
  String _specialty = 'Cardiology';
  final _subSpecialtyController = TextEditingController();
  final _prcNumberController = TextEditingController();
  DateTime? _licenseExpiry;
  final _yearsExpController = TextEditingController(text: '5');
  final _medicalSchoolController = TextEditingController();
  final _gradYearController = TextEditingController();
  final Set<String> _languages = {'English', 'Tagalog'};
  final _bioController = TextEditingController();
  String? _prcPhotoPath;

  // Doctor Clinic
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _directionsController = TextEditingController();
  final bool _walkIns = true;
  double _clinicLat = 14.5995;
  double _clinicLng = 120.9842;
  double? _clinicAccuracy;

  // Doctor Services
  final Set<String> _visitTypes = {'In person', 'Video call'};
  double _fee = 500.0;
  final int _slotMinutes = 30;
  final Map<int, bool> _weeklyDays = {
    1: true,
    2: true,
    3: true,
    4: true,
    5: true,
    6: false,
    7: false,
  };

  // Consent
  bool _consentInfoCorrect = false;
  bool _consentTerms = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _customAllergyController.dispose();
    _medicationController.dispose();
    _philhealthController.dispose();
    _subSpecialtyController.dispose();
    _prcNumberController.dispose();
    _yearsExpController.dispose();
    _medicalSchoolController.dispose();
    _gradYearController.dispose();
    _bioController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  int get _totalSteps => _role == 'patient' ? 5 : 6;

  int? get _computedAge {
    if (_dob == null) return null;
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleNext() async {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!_accountCreated) {
        final success = await authProvider.register(
          fullName: 'New User',
          email: _emailController.text,
          password: _passwordController.text,
          role: _role,
        );

        if (!success) {
          if (mounted && authProvider.errorMessage != null && authProvider.errorMessage!.contains('already exists')) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Email Exists'),
                content: const Text('This email already has an account. Sign in instead?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacementNamed(context, RouteNames.login);
                    },
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            );
          }
          return;
        }
        _accountCreated = true;
      }
    } else if (_currentStep == 2) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First name and Last name are required.')));
        return;
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave sign-up?'),
          content: const Text('Your progress is saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, RouteNames.welcome);
              },
              child: const Text('Leave'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _photoPath = img.path;
      });
    }
  }

  Future<void> _pickPrcPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _prcPhotoPath = img.path;
      });
    }
  }

  Future<void> _useGps() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      setState(() {
        _clinicLat = pos.latitude;
        _clinicLng = pos.longitude;
        _clinicAccuracy = pos.accuracy;
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      final address = await LocationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (address != null && _clinicAddressController.text.isEmpty) {
        _clinicAddressController.text = address;
      }
    }
  }

  void _finish() async {
    if (!_consentInfoCorrect || !_consentTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept terms and confirm information accuracy.')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final suffixStr = _suffixController.text.trim().isNotEmpty ? ' ${_suffixController.text.trim()}' : '';
    final rawFullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}$suffixStr';
    final fullName = _role == 'doctor' && !rawFullName.startsWith('Dr.') ? 'Dr. $rawFullName' : rawFullName;

    final nowIso = DateTime.now().toIso8601String();

    final userData = {
      'full_name': fullName,
      'first_name': _firstNameController.text.trim(),
      'middle_name': _middleNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'suffix': _suffixController.text.trim(),
      'phone': _phoneController.text.trim(),
      'photo_path': _photoPath,
    };

    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);

    if (_role == 'patient') {
      final profileData = {
        'emergency_name': _emergencyNameController.text.trim(),
        'emergency_relation': _emergencyRelationController.text.trim(),
        'emergency_phone': _emergencyPhoneController.text.trim(),
        'blood_type': _bloodType,
        'height_cm': double.tryParse(_heightController.text.trim()),
        'weight_kg': double.tryParse(_weightController.text.trim()),
        'allergies': _allergies.join(', '),
        'conditions': _conditions.join(', '),
        'medications': _medications.join(', '),
        'philhealth_no': _philhealthController.text.trim(),
      };

      final success = await onboardingProvider.finishPatientOnboarding(
        userId: userId,
        userData: userData,
        profileData: profileData,
      );

      if (mounted && success) {
        await authProvider.refreshCurrentUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, ${_firstNameController.text.trim()}!')));
          Navigator.pushNamedAndRemoveUntil(context, RouteNames.patientHome, (route) => false);
        }
      }
    } else {
      final doctorData = {
        'specialty': _specialty,
        'bio': _bioController.text.trim(),
        'years_experience': int.tryParse(_yearsExpController.text.trim()) ?? 0,
        'consultation_fee': _fee,
        'clinic_name': _clinicNameController.text.trim(),
        'clinic_address': _clinicAddressController.text.trim(),
        'clinic_phone': _clinicPhoneController.text.trim(),
        'directions_note': _directionsController.text.trim(),
        'walk_ins': _walkIns ? 1 : 0,
        'latitude': _clinicLat,
        'longitude': _clinicLng,
        'location_accuracy': _clinicAccuracy ?? 10.0,
        'location_updated_at': nowIso,
      };

      final doctorProfileData = {
        'specialty': _specialty,
        'sub_specialty': _subSpecialtyController.text.trim(),
        'prc_number': _prcNumberController.text.trim(),
        'license_expiry': _licenseExpiry?.toIso8601String(),
        'years_experience': int.tryParse(_yearsExpController.text.trim()) ?? 0,
        'medical_school': _medicalSchoolController.text.trim(),
        'graduation_year': int.tryParse(_gradYearController.text.trim()),
        'languages': _languages.join(', '),
        'bio': _bioController.text.trim(),
        'prc_photo_path': _prcPhotoPath,
        'verification_status': 'pending',
      };

      final success = await onboardingProvider.finishDoctorOnboarding(
        userId: userId,
        userData: userData,
        doctorData: doctorData,
        doctorProfileData: doctorProfileData,
      );

      if (mounted && success) {
        await authProvider.refreshCurrentUser();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, RouteNames.doctorDashboard, (route) => false);
        }
      }
    }
  }

  void _jumpToStep(int targetStep) {
    setState(() {
      _currentStep = targetStep;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final onboardingProvider = Provider.of<OnboardingProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
          onPressed: _prevStep,
        ),
        actions: [
          if (_accountCreated)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.navy),
              tooltip: 'Sign out',
              onPressed: () {
                authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: StepProgressBar(currentStep: _currentStep, totalSteps: _totalSteps),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: _buildWizardStep(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 1) ...[
                    Expanded(
                      child: NeutralOutlinedButton(
                        text: 'Back',
                        onPressed: _prevStep,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      text: _currentStep == _totalSteps ? 'Finish' : 'Next',
                      isLoading: onboardingProvider.isLoading || authProvider.isLoading,
                      onPressed: (_currentStep == _totalSteps && (!_consentInfoCorrect || !_consentTerms))
                          ? null
                          : (_currentStep == _totalSteps ? _finish : _handleNext),
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

  Widget _buildWizardStep() {
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppLogo(size: 80)),
          const SizedBox(height: 16),
          const Text('Create Your Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 16),

          // Role Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _accountCreated ? null : () => setState(() => _role = 'patient'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _role == 'patient' ? AppColors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Patient', textAlign: TextAlign.center, style: TextStyle(fontWeight: _role == 'patient' ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _accountCreated ? null : () => setState(() => _role = 'doctor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _role == 'doctor' ? AppColors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Doctor', textAlign: TextAlign.center, style: TextStyle(fontWeight: _role == 'doctor' ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(label: 'Email *', hint: 'enter your email', controller: _emailController, keyboardType: TextInputType.emailAddress, validator: Validators.email),
          const SizedBox(height: 16),
          AppTextField(label: 'Password *', hint: 'at least 6 characters', controller: _passwordController, obscureText: _obscurePassword, validator: (v) => v != null && v.length >= 6 ? null : 'At least 6 characters'),
          const SizedBox(height: 16),
          AppTextField(label: 'Confirm Password *', hint: 're-enter password', controller: _confirmPasswordController, obscureText: _obscurePassword, validator: Validators.required),
        ],
      );
    }

    if (_role == 'patient') {
      switch (_currentStep) {
        case 2: // Personal
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.tint,
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null ? const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.blue) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'First Name *', hint: 'First name', controller: _firstNameController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'Middle Name', hint: 'Middle name', controller: _middleNameController),
              const SizedBox(height: 12),
              AppTextField(label: 'Last Name *', hint: 'Last name', controller: _lastNameController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'Suffix', hint: 'e.g. Jr, III', controller: _suffixController),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dob == null ? 'Date of Birth *' : 'DOB: ${DateFormat('MMM dd, yyyy').format(_dob!)} (${_computedAge ?? 0} yrs)'),
                trailing: const Icon(Icons.calendar_month_outlined, color: AppColors.blue),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                  if (date != null) setState(() => _dob = date);
                },
              ),
            ],
          );
        case 3: // Contact
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contact & Emergency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              AppTextField(label: 'Mobile Number *', hint: '09171234567', controller: _phoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
              const SizedBox(height: 12),
              AppTextField(label: 'House / Street *', hint: 'Address', controller: _streetController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'City *', hint: 'City', controller: _cityController, validator: Validators.required),
              const SizedBox(height: 16),
              const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 12),
              AppTextField(label: 'Contact Name *', hint: 'Full Name', controller: _emergencyNameController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'Contact Phone *', hint: '09171234567', controller: _emergencyPhoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
            ],
          );
        case 4: // Medical
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _bloodType,
                decoration: const InputDecoration(labelText: 'Blood Type'),
                items: ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _bloodType = v!),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'PhilHealth Number', hint: 'Optional', controller: _philhealthController),
            ],
          );
        case 5: // Review
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review & Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              _buildReviewSection('Personal Information', 2, [
                'Name: ${_firstNameController.text} ${_lastNameController.text}',
                if (_dob != null) 'DOB: ${DateFormat('MMM dd, yyyy').format(_dob!)}',
              ]),
              const SizedBox(height: 12),
              _buildReviewSection('Contact Information', 3, [
                'Phone: ${_phoneController.text}',
                'Address: ${_streetController.text}, ${_cityController.text}',
              ]),
              const SizedBox(height: 20),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _consentInfoCorrect,
                title: const Text('I confirm the information provided is correct.', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() => _consentInfoCorrect = v!),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _consentTerms,
                title: const Text('I agree to the Terms of Service & Privacy Policy.', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() => _consentTerms = v!),
              ),
            ],
          );
      }
    } else {
      // DOCTOR STEPS
      switch (_currentStep) {
        case 2: // Personal
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Doctor Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.tint,
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null ? const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.blue) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'First Name *', hint: 'First name', controller: _firstNameController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'Last Name *', hint: 'Last name', controller: _lastNameController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'Mobile Phone *', hint: '09171234567', controller: _phoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
            ],
          );
        case 3: // Professional
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Professional Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(labelText: 'Specialty *'),
                items: ['Cardiology', 'Pediatrics', 'Dermatologist', 'General Medicine', 'OB-GYN'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _specialty = v!),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'PRC License Number *', hint: 'e.g. 1234567', controller: _prcNumberController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'Bio / Intro *', hint: 'Minimum 20 characters', controller: _bioController, maxLines: 3, validator: Validators.required),
              const SizedBox(height: 12),
              SecondaryButton(
                text: _prcPhotoPath != null ? 'PRC ID Uploaded ✓' : 'Upload PRC ID Photo',
                icon: Icons.upload_file_rounded,
                onPressed: _pickPrcPhoto,
              ),
            ],
          );
        case 4: // Clinic
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Clinic Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              AppTextField(label: 'Clinic Name *', hint: 'Clinic Name', controller: _clinicNameController, validator: Validators.required),
              const SizedBox(height: 12),
              AppTextField(label: 'Clinic Address *', hint: 'Street address', controller: _clinicAddressController, validator: Validators.required),
              const SizedBox(height: 12),
              SecondaryButton(text: 'Capture GPS Location', icon: Icons.my_location_rounded, onPressed: _useGps),
              const SizedBox(height: 12),
              ClinicMapCard(latitude: _clinicLat, longitude: _clinicLng, clinicName: _clinicNameController.text.isEmpty ? 'Clinic' : _clinicNameController.text, height: 160),
            ],
          );
        case 5: // Services
          final daysOfWeek = {
            1: 'Monday',
            2: 'Tuesday',
            3: 'Wednesday',
            4: 'Thursday',
            5: 'Friday',
            6: 'Saturday',
            7: 'Sunday',
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Services & Fee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              Text('Consultation Fee: ₱${_fee.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Slider(value: _fee, min: 0, max: 3000, divisions: 60, label: '₱${_fee.toInt()}', onChanged: (v) => setState(() => _fee = v)),
              const SizedBox(height: 16),
              const Text('Weekly Hours (Schedule)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 8),
              ...daysOfWeek.entries.map((entry) {
                final dayNum = entry.key;
                final dayName = entry.value;
                final isEnabled = _weeklyDays[dayNum] ?? false;

                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isEnabled ? '09:00 AM - 05:00 PM' : 'Closed', style: const TextStyle(fontSize: 12)),
                  value: isEnabled,
                  onChanged: (val) {
                    setState(() {
                      _weeklyDays[dayNum] = val;
                    });
                  },
                );
              }),
            ],
          );
        case 6: // Review
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review & Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              _buildReviewSection('Professional Info', 3, [
                'Name: Dr. ${_firstNameController.text} ${_lastNameController.text}',
                'Specialty: $_specialty',
                'PRC #: ${_prcNumberController.text}',
              ]),
              const SizedBox(height: 12),
              _buildReviewSection('Clinic Info', 4, [
                'Clinic: ${_clinicNameController.text}',
                'Address: ${_clinicAddressController.text}',
                'Fee: ₱${_fee.toInt()}',
              ]),
              const SizedBox(height: 20),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _consentInfoCorrect,
                title: const Text('I confirm my medical license & credentials are valid and true.', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() => _consentInfoCorrect = v!),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _consentTerms,
                title: const Text('I agree to the Terms of Service & Privacy Policy.', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() => _consentTerms = v!),
              ),
            ],
          );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildReviewSection(String title, int stepNum, List<String> details) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 15)),
                TextLinkButton(text: 'Edit', onPressed: () => _jumpToStep(stepNum)),
              ],
            ),
            const Divider(),
            ...details.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(d, style: const TextStyle(fontSize: 13, color: AppColors.navy)),
                )),
          ],
        ),
      ),
    );
  }
}
