import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/user_avatar.dart';
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

  void _showChangePhotoSheet() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.blue),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final img = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, imageQuality: 80);
                  if (img != null) {
                    final ok = await authProvider.updatePhoto(img.path);
                    if (mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.blue),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
                  if (img != null) {
                    final ok = await authProvider.updatePhoto(img.path);
                    if (mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
                    }
                  }
                },
              ),
              if (user?.photoPath != null && user!.photoPath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  title: const Text('Remove photo', style: TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await authProvider.updatePhoto(null);
                    if (mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        title: const Text(
          'Sign out?',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "You'll need to sign in again to see your visits.",
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            DangerButton(
              text: 'Yes, sign out',
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();

                messenger.showSnackBar(
                  const SnackBar(content: Text("You've been signed out.")),
                );

                nav.pushNamedAndRemoveUntil(
                  RouteNames.login,
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 12),
            NeutralOutlinedButton(
              text: 'Stay signed in',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        UserAvatar(
                          photoPath: user?.photoPath,
                          name: user?.fullName ?? 'Patient',
                          size: 80,
                          onTap: _showChangePhotoSheet,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showChangePhotoSheet,
                            child: const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.blue,
                              child: Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
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
              DangerOutlinedButton(
                text: 'Sign out',
                onPressed: _showSignOutDialog,
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
