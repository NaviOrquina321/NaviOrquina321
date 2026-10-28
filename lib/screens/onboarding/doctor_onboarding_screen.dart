import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
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

class DoctorOnboardingScreen extends StatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  State<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends State<DoctorOnboardingScreen> {
  int _currentStep = 1;

  // Step 1
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController(text: 'MD');
  final _phoneController = TextEditingController();
  String? _photoPath;

  // Step 2
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

  // Step 3
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _directionsController = TextEditingController();
  final bool _walkIns = true;
  double _latitude = 14.5995;
  double _longitude = 120.9842;
  double? _accuracy;

  // Step 4
  final Set<String> _visitTypes = {'In person', 'Video call'};
  double _fee = 500.0;
  int _slotMinutes = 30;
  final Map<int, bool> _weeklyDays = {
    1: true,
    2: true,
    3: true,
    4: true,
    5: true,
    6: false,
    7: false,
  };

  // Step 5
  bool _consentInfoCorrect = false;
  bool _consentTerms = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _phoneController.dispose();
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

  void _nextStep() {
    if (_currentStep == 1) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First name and Last name are required.')));
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number is required.')));
        return;
      }
    } else if (_currentStep == 2) {
      if (_prcNumberController.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid PRC license number is required.')));
        return;
      }
      if (_bioController.text.trim().length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bio must be at least 20 characters.')));
        return;
      }
    } else if (_currentStep == 3) {
      if (_clinicNameController.text.trim().isEmpty || _clinicAddressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clinic name and address are required.')));
        return;
      }
    } else if (_currentStep == 4) {
      if (_visitTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one visit type.')));
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
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _accuracy = pos.accuracy;
      });
      final address = await LocationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (address != null && _clinicAddressController.text.isEmpty) {
        _clinicAddressController.text = address;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS Position Captured! Accuracy: ${pos.accuracy.toStringAsFixed(0)} m')),
        );
      }
    }
  }

  void _pinOnMap() async {
    final LatLng? result = await Navigator.pushNamed(
      context,
      RouteNames.pinClinic,
      arguments: {'lat': _latitude, 'lng': _longitude},
    ) as LatLng?;

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _accuracy = 5.0;
      });
    }
  }

  void _finish() async {
    if (!_consentInfoCorrect || !_consentTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept terms and confirm accuracy.')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final fullName = 'Dr. ${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
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
      'latitude': _latitude,
      'longitude': _longitude,
      'location_accuracy': _accuracy ?? 10.0,
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

    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final onboardingProvider = Provider.of<OnboardingProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.navy),
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
              child: StepProgressBar(currentStep: _currentStep, totalSteps: 5),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: _buildStepContent(),
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
                      text: _currentStep == 5 ? 'Finish' : 'Next',
                      isLoading: onboardingProvider.isLoading,
                      onPressed: _currentStep == 5 ? _finish : _nextStep,
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: AppLogo(size: 80)),
            const SizedBox(height: 16),
            const Text('Doctor Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
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
            AppTextField(label: 'Suffix', hint: 'MD', controller: _suffixController),
            const SizedBox(height: 12),
            AppTextField(label: 'Mobile Phone *', hint: '09171234567', controller: _phoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Professional Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _specialty,
              decoration: const InputDecoration(labelText: 'Specialty *'),
              items: ['Cardiology', 'Pediatrics', 'Dermatologist', 'General Medicine', 'OB-GYN', 'ENT', 'Orthopedics', 'Psychiatry']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _specialty = v!),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Sub-specialty', hint: 'e.g. Interventional Cardiology', controller: _subSpecialtyController),
            const SizedBox(height: 12),
            AppTextField(label: 'PRC License Number *', hint: 'e.g. 1234567', controller: _prcNumberController, keyboardType: TextInputType.number, validator: Validators.required),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_licenseExpiry == null ? 'License Expiry Date *' : 'License Expiry: ${DateFormat('MMM dd, yyyy').format(_licenseExpiry!)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
              trailing: const Icon(Icons.calendar_month_outlined, color: AppColors.blue),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2040),
                );
                if (date != null) {
                  setState(() {
                    _licenseExpiry = date;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Years of Experience *', hint: 'e.g. 5', controller: _yearsExpController, keyboardType: TextInputType.number, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Medical School *', hint: 'e.g. UST Faculty of Medicine', controller: _medicalSchoolController),
            const SizedBox(height: 12),
            AppTextField(label: 'Graduation Year *', hint: 'e.g. 2015', controller: _gradYearController, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            const Text('Languages Spoken', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['English', 'Tagalog', 'Cebuano', 'Ilocano'].map((lang) {
                final isSelected = _languages.contains(lang);
                return FilterChip(
                  label: Text(lang),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val ? _languages.add(lang) : _languages.remove(lang);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Bio / Profile Intro *', hint: 'Minimum 20 characters introducing yourself', controller: _bioController, maxLines: 3, validator: Validators.required),
            const SizedBox(height: 12),
            SecondaryButton(
              text: _prcPhotoPath != null ? 'PRC ID Uploaded ✓' : 'Upload PRC ID Photo',
              icon: Icons.upload_file_rounded,
              onPressed: _pickPrcPhoto,
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clinic Details & Live Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            AppTextField(label: 'Clinic Name *', hint: 'Central Health Clinic', controller: _clinicNameController, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Clinic Address *', hint: 'Full street address', controller: _clinicAddressController, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Clinic Phone *', hint: '+63 2 8123 4567', controller: _clinicPhoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Capture GPS Location',
                    icon: Icons.my_location_rounded,
                    onPressed: _useGps,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeutralOutlinedButton(
                    text: 'Pin on map',
                    icon: Icons.map_rounded,
                    onPressed: _pinOnMap,
                  ),
                ),
              ],
            ),
            if (_accuracy != null) ...[
              const SizedBox(height: 8),
              Text(
                'GPS Accuracy: ${_accuracy!.toStringAsFixed(1)} meters',
                style: TextStyle(fontSize: 12, color: _accuracy! <= 50 ? AppColors.blue : AppColors.danger, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 12),
            ClinicMapCard(
              latitude: _latitude,
              longitude: _longitude,
              clinicName: _clinicNameController.text.isEmpty ? 'Clinic' : _clinicNameController.text,
              height: 180,
            ),
          ],
        );
      case 4:
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
            const Text('Services & Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            const Text('Visit Types Offered *', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['In person', 'Video call'].map((type) {
                final isSelected = _visitTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val ? _visitTypes.add(type) : _visitTypes.remove(type);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Consultation Fee: ₱${_fee.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Slider(
              value: _fee,
              min: 0,
              max: 3000,
              divisions: 60,
              label: '₱${_fee.toInt()}',
              onChanged: (v) => setState(() => _fee = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _slotMinutes,
              decoration: const InputDecoration(labelText: 'Slot Duration'),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
              ],
              onChanged: (v) => setState(() => _slotMinutes = v!),
            ),
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
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review & Consent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${_firstNameController.text} ${_lastNameController.text}, ${_suffixController.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Specialty: $_specialty'),
                    Text('PRC #: ${_prcNumberController.text}'),
                    Text('Clinic: ${_clinicNameController.text}'),
                    Text('Fee: ₱${_fee.toInt()}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _consentInfoCorrect,
              title: const Text('I confirm my medical license & credentials are valid and true.', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _consentInfoCorrect = v!),
            ),
            CheckboxListTile(
              value: _consentTerms,
              title: const Text('I agree to the Terms of Service & Privacy Policy.', style: TextStyle(fontSize: 13)),
              onChanged: (v) => setState(() => _consentTerms = v!),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
