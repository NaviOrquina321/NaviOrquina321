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
import '../../core/widgets/step_progress_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/location_service.dart';

class PatientOnboardingScreen extends StatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  State<PatientOnboardingScreen> createState() => _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  int _currentStep = 1;

  // Step 1 Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  DateTime? _dob;
  String _sex = 'Male';
  final String _civilStatus = 'Single';
  String? _photoPath;

  // Step 2 Controllers
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _zipController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Step 3 Controllers
  String _bloodType = 'O+';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final Set<String> _allergies = {'Penicillin'};
  final _customAllergyController = TextEditingController();
  final Set<String> _conditions = {};
  final List<String> _medications = [];
  final _medicationController = TextEditingController();
  final _philhealthController = TextEditingController();

  // Step 4 Consents
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
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _zipController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _customAllergyController.dispose();
    _medicationController.dispose();
    _philhealthController.dispose();
    super.dispose();
  }

  int? get _computedAge {
    if (_dob == null) return null;
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First name and Last name are required.')));
        return;
      }
      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date of birth is required.')));
        return;
      }
    } else if (_currentStep == 2) {
      if (_phoneController.text.trim().length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid mobile number is required (e.g. 09171234567).')));
        return;
      }
      if (_streetController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _provinceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address details are required.')));
        return;
      }
      if (_emergencyNameController.text.trim().isEmpty || _emergencyPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency contact details are required.')));
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      final address = await LocationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (address != null) {
        _streetController.text = address;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location captured from GPS!')));
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

    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    final userData = {
      'full_name': fullName,
      'first_name': _firstNameController.text.trim(),
      'middle_name': _middleNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'suffix': _suffixController.text.trim(),
      'birth_date': _dob?.toIso8601String(),
      'sex': _sex,
      'civil_status': _civilStatus,
      'phone': _phoneController.text.trim(),
      'house_street': _streetController.text.trim(),
      'barangay': _barangayController.text.trim(),
      'city': _cityController.text.trim(),
      'province': _provinceController.text.trim(),
      'zip': _zipController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'photo_path': _photoPath,
    };

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

    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final success = await onboardingProvider.finishPatientOnboarding(
      userId: userId,
      userData: userData,
      profileData: profileData,
    );

    if (mounted && success) {
      await authProvider.refreshCurrentUser();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.patientHome, (route) => false);
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
        title: const Text('Patient Setup'),
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
              child: StepProgressBar(currentStep: _currentStep, totalSteps: 4),
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
                      text: _currentStep == 4 ? 'Finish' : 'Next',
                      isLoading: onboardingProvider.isLoading,
                      onPressed: _currentStep == 4 ? _finish : _nextStep,
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
            const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.tint,
                  backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null ? const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.blue) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'First Name *', hint: 'Enter first name', controller: _firstNameController, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Middle Name', hint: 'Enter middle name', controller: _middleNameController),
            const SizedBox(height: 12),
            AppTextField(label: 'Last Name *', hint: 'Enter last name', controller: _lastNameController, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Suffix', hint: 'e.g. Jr, III', controller: _suffixController),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _dob == null
                    ? 'Date of Birth *'
                    : 'DOB: ${DateFormat('MMM dd, yyyy').format(_dob!)} (${_computedAge ?? 0} yrs old)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              trailing: const Icon(Icons.calendar_month_outlined, color: AppColors.blue),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dob = date;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sex,
              decoration: const InputDecoration(labelText: 'Sex *'),
              items: ['Male', 'Female', 'Prefer not to say'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _sex = v!),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact & Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            AppTextField(label: 'Mobile Number *', hint: 'e.g. 09171234567', controller: _phoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
            const SizedBox(height: 12),
            AppTextField(label: 'House / Street *', hint: 'Street address', controller: _streetController, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Barangay *', hint: 'Barangay', controller: _barangayController),
            const SizedBox(height: 12),
            AppTextField(label: 'City / Municipality *', hint: 'City', controller: _cityController, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Province *', hint: 'Province', controller: _provinceController, validator: Validators.required),
            const SizedBox(height: 12),
            SecondaryButton(
              text: 'Use my current location',
              icon: Icons.my_location_rounded,
              onPressed: _useCurrentLocation,
            ),
            const SizedBox(height: 20),
            const Text('Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 12),
            AppTextField(label: 'Emergency Name *', hint: 'Contact person', controller: _emergencyNameController, validator: Validators.required),
            const SizedBox(height: 12),
            AppTextField(label: 'Relationship *', hint: 'e.g. Spouse, Parent', controller: _emergencyRelationController),
            const SizedBox(height: 12),
            AppTextField(label: 'Emergency Phone *', hint: 'e.g. 09171234567', controller: _emergencyPhoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 4),
            const Text('This info is only visible to doctors you book with.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _bloodType,
              decoration: const InputDecoration(labelText: 'Blood Type'),
              items: ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _bloodType = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'Height (cm)', hint: 'e.g. 170', controller: _heightController, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Weight (kg)', hint: 'e.g. 65', controller: _weightController, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Allergies', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Penicillin', 'Peanuts', 'Dust', 'Latex'].map((alg) {
                final isSelected = _allergies.contains(alg);
                return FilterChip(
                  label: Text(alg),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val ? _allergies.add(alg) : _allergies.remove(alg);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Add Custom Allergy',
                    hint: 'e.g. Seafood',
                    controller: _customAllergyController,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.blue, size: 32),
                  onPressed: () {
                    final text = _customAllergyController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _allergies.add(text);
                        _customAllergyController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Known Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Hypertension', 'Diabetes', 'Asthma', 'Heart Disease'].map((cond) {
                final isSelected = _conditions.contains(cond);
                return FilterChip(
                  label: Text(cond),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val ? _conditions.add(cond) : _conditions.remove(cond);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Current Medications', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Medicine Name',
                    hint: 'e.g. Amlodipine 5mg',
                    controller: _medicationController,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.blue, size: 32),
                  onPressed: () {
                    final text = _medicationController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _medications.add(text);
                        _medicationController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_medications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _medications.map((med) {
                  return Chip(
                    label: Text(med),
                    onDeleted: () {
                      setState(() {
                        _medications.remove(med);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              label: 'PhilHealth Number',
              hint: '12-digit number',
              controller: _philhealthController,
              keyboardType: TextInputType.number,
            ),
          ],
        );
      case 4:
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
                    Text('Name: ${_firstNameController.text} ${_lastNameController.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Phone: ${_phoneController.text}'),
                    Text('Address: ${_streetController.text}, ${_cityController.text}'),
                    Text('Emergency: ${_emergencyNameController.text} (${_emergencyPhoneController.text})'),
                    if (_allergies.isNotEmpty) Text('Allergies: ${_allergies.join(", ")}'),
                    if (_conditions.isNotEmpty) Text('Conditions: ${_conditions.join(", ")}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _consentInfoCorrect,
              title: const Text('I confirm the information provided is correct.', style: TextStyle(fontSize: 13)),
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
