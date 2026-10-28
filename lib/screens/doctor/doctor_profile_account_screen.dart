import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/switch_row.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';

class DoctorProfileAccountScreen extends StatefulWidget {
  const DoctorProfileAccountScreen({super.key});

  @override
  State<DoctorProfileAccountScreen> createState() => _DoctorProfileAccountScreenState();
}

class _DoctorProfileAccountScreenState extends State<DoctorProfileAccountScreen> {
  bool _isEditingProfile = false;
  final _specialtyController = TextEditingController();
  final _roomController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      final docProvider = Provider.of<DoctorProvider>(context, listen: false);
      await docProvider.fetchDoctorProfileForUser(userId);
      final doc = docProvider.currentDoctorProfile;
      if (doc != null) {
        _specialtyController.text = doc.specialty ?? '';
        _roomController.text = doc.room ?? '';
        _bioController.text = doc.bio ?? '';
      }
    }
  }

  @override
  void dispose() {
    _specialtyController.dispose();
    _roomController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final docProvider = Provider.of<DoctorProvider>(context, listen: false);
    final doc = docProvider.currentDoctorProfile;
    if (doc?.id == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await docProvider.updateDoctorProfile(
      doc!.id!,
      specialty: _specialtyController.text.trim(),
      room: _roomController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (success) {
      setState(() {
        _isEditingProfile = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final docProvider = Provider.of<DoctorProvider>(context);

    final user = authProvider.currentUser;
    final doc = docProvider.currentDoctorProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
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
                      name: user?.fullName ?? 'Doctor',
                      radius: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Dr. Medical',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc?.specialty ?? 'Specialist'} • ${doc?.room ?? 'Room'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_isEditingProfile) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Doctor Profile',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Specialty',
                          controller: _specialtyController,
                          validator: (val) => Validators.requiredField(val, 'Specialty'),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Room',
                          controller: _roomController,
                          validator: (val) => Validators.requiredField(val, 'Room'),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Biography',
                          controller: _bioController,
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
                                    _isEditingProfile = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                text: 'Save',
                                isLoading: docProvider.isLoading,
                                onPressed: _handleSaveProfile,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                if (doc != null)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SwitchRow(
                        title: 'Auto-confirm appointments',
                        subtitle: 'Automatically confirm incoming patient requests',
                        value: doc.autoConfirm == 1,
                        onChanged: (val) async {
                          await docProvider.updateDoctorProfile(
                            doc.id!,
                            autoConfirm: val,
                          );
                          _loadProfile();
                        },
                      ),
                    ),
                  ),

                _buildProfileRow(
                  Icons.edit_outlined,
                  'Edit profile details',
                  onTap: () {
                    setState(() {
                      _isEditingProfile = true;
                    });
                  },
                ),
                _buildProfileRow(
                  Icons.local_hospital_outlined,
                  'Clinic details',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clinic details placeholder.')),
                    );
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
      bottomNavigationBar: DoctorBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorDashboard);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorPatients);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorAvailability);
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
