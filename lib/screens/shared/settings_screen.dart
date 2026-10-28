import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/switch_row.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      Provider.of<SettingsProvider>(context, listen: false).fetchSettings(userId);
    }
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (mounted) {
      setState(() {
        _locationPermissionStatus = status;
      });
    }
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Old Password',
                  controller: oldPassController,
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'New Password',
                  controller: newPassController,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirm New Password',
                  controller: confirmPassController,
                  obscureText: true,
                  validator: (v) => v != newPassController.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.currentUser?.id;
                if (userId == null) return;

                final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                final success = await settingsProvider.changePassword(
                  userId,
                  oldPassController.text,
                  newPassController.text,
                );

                navigator.pop();
                if (success) {
                  messenger.showSnackBar(const SnackBar(content: Text('Password changed successfully.')));
                } else {
                  messenger.showSnackBar(SnackBar(content: Text(settingsProvider.errorMessage ?? 'Failed to change password.')));
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final deleteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Account', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and will delete all your appointments and history. Type DELETE to confirm.',
                style: TextStyle(color: AppColors.navy, fontSize: 13),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Type DELETE',
                controller: deleteController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.white,
              ),
              onPressed: () async {
                if (deleteController.text.trim() != 'DELETE') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please type DELETE to confirm.')),
                  );
                  return;
                }

                final navigator = Navigator.of(context);
                Navigator.pop(ctx);

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.currentUser?.id;
                if (userId == null) return;

                final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                final success = await settingsProvider.deleteAccount(userId);

                if (success) {
                  await authProvider.logout();
                  navigator.pushNamedAndRemoveUntil(RouteNames.welcome, (route) => false);
                }
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  void _showRemindBeforeBottomSheet(UserSettings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Remind me before visit', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('1 hour before'),
                trailing: s.remindBefore == '1 hour' ? const Icon(Icons.check, color: AppColors.blue) : null,
                onTap: () {
                  _updateSettings(s.copyWith(remindBefore: '1 hour'));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('1 day before'),
                trailing: s.remindBefore == '1 day' ? const Icon(Icons.check, color: AppColors.blue) : null,
                onTap: () {
                  _updateSettings(s.copyWith(remindBefore: '1 day'));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateSettings(UserSettings updated) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.updateSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsProvider.isLoading || settings == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications & Preferences',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SwitchRow(
                              title: 'Appointment reminders',
                              value: settings.remindersOn,
                              onChanged: (val) => _updateSettings(settings.copyWith(remindersOn: val)),
                            ),
                            const Divider(height: 20),
                            SwitchRow(
                              title: 'Chat messages',
                              value: settings.chatOn,
                              onChanged: (val) => _updateSettings(settings.copyWith(chatOn: val)),
                            ),
                            const Divider(height: 20),
                            SwitchRow(
                              title: 'Offers & news',
                              value: settings.offersOn,
                              onChanged: (val) => _updateSettings(settings.copyWith(offersOn: val)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'App Settings',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language_outlined, color: AppColors.blue),
                            title: const Text('Language', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('English', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('More languages coming soon.')),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.alarm_outlined, color: AppColors.blue),
                            title: const Text('Remind me', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(settings.remindBefore, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                            onTap: () => _showRemindBeforeBottomSheet(settings),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.blue),
                            title: const Text('Location access', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('Status: ${_locationPermissionStatus.name}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.muted),
                            onTap: () async {
                              await openAppSettings();
                              _checkLocationPermission();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Account Security',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_outline, color: AppColors.blue),
                            title: const Text('Change password', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                            onTap: _showChangePasswordDialog,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
                            title: const Text('Delete account', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 14)),
                            onTap: _showDeleteAccountDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
