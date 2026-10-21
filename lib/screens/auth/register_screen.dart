import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _roomController = TextEditingController();

  bool _isPatientSelected = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _specialtyController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = _isPatientSelected ? 'patient' : 'doctor';

    final success = await authProvider.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: role,
      specialty: !_isPatientSelected ? _specialtyController.text : null,
      room: !_isPatientSelected ? _roomController.text : null,
    );

    if (mounted) {
      if (success) {
        if (_isPatientSelected) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.patientHome,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.doctorDashboard,
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.tint,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_hospital_rounded,
                        size: 40,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Segmented Switch
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPatientSelected = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isPatientSelected ? AppColors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _isPatientSelected
                                  ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                  : [],
                            ),
                            child: Text(
                              'Patient',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: _isPatientSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPatientSelected = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isPatientSelected ? AppColors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: !_isPatientSelected
                                  ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                  : [],
                            ),
                            child: Text(
                              'Doctor',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: !_isPatientSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (authProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cancelledBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                AppTextField(
                  label: 'Full Name',
                  hint: 'enter your full name',
                  controller: _fullNameController,
                  validator: (val) => Validators.requiredField(val, 'Full name'),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Email',
                  hint: 'enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.muted),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Password',
                  hint: 'at least 8 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                if (!_isPatientSelected) ...[
                  AppTextField(
                    label: 'Specialty',
                    hint: 'e.g., Cardiologist, Pediatrician',
                    controller: _specialtyController,
                    validator: (val) => Validators.requiredField(val, 'Specialty'),
                    prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Room',
                    hint: 'e.g., Room 3',
                    controller: _roomController,
                    validator: (val) => Validators.requiredField(val, 'Room'),
                    prefixIcon: const Icon(Icons.meeting_room_outlined, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 12),
                AppButton(
                  text: 'Create Account',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
