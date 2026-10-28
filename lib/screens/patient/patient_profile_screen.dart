import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../providers/auth_provider.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isEditingPersonalInfo = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePersonalInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      _nameController.text,
      _emailController.text,
    );

    if (mounted && success) {
      setState(() {
        _isEditingPersonalInfo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    AvatarInitials(
                      name: user?.fullName ?? 'Patient',
                      radius: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Patient Name',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Patient',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_isEditingPersonalInfo) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Personal Information',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Full Name',
                          controller: _nameController,
                          validator: (val) => Validators.requiredField(val, 'Full name'),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Email',
                          controller: _emailController,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Cancel',
                                isSecondary: true,
                                onPressed: () {
                                  setState(() {
                                    _isEditingPersonalInfo = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                text: 'Save',
                                isLoading: authProvider.isLoading,
                                onPressed: _handleSavePersonalInfo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                _buildProfileRow(
                  Icons.person_outline,
                  'Personal information',
                  onTap: () {
                    setState(() {
                      _isEditingPersonalInfo = true;
                    });
                  },
                ),
                _buildProfileRow(
                  Icons.history,
                  'Medical history',
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.medicalRecords);
                  },
                ),
                _buildProfileRow(
                  Icons.notifications_outlined,
                  'Notifications',
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.reminders);
                  },
                ),
                _buildProfileRow(
                  Icons.help_outline,
                  'Help & support',
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.helpSupport);
                  },
                ),
                _buildProfileRow(
                  Icons.settings_outlined,
                  'Settings',
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.settings);
                  },
                ),
              ],

              const SizedBox(height: 32),
              AppButton(
                text: 'Sign out',
                isDanger: true,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await authProvider.logout();
                    nav.pushNamedAndRemoveUntil(
                      RouteNames.login,
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PatientBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, RouteNames.patientHome);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, RouteNames.patientDoctors);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, RouteNames.myVisits);
          }
        },
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, {required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.blue),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}
