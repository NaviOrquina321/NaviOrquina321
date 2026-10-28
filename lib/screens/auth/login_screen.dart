import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPatientSelected = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expectedRole = _isPatientSelected ? 'patient' : 'doctor';

    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
      expectedRole: expectedRole,
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
        title: const Text('Sign In'),
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
                const SizedBox(height: 24),

                // Role Segmented Control
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
                const SizedBox(height: 24),

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
                  hint: 'enter your password',
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
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.forgotPassword);
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                AppButton(
                  text: _isPatientSelected ? 'Sign in as patient' : 'Sign in as doctor',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.blue),
                    label: const Text(
                      'Need help?',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.helpSupport);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
