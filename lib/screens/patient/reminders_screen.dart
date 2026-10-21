import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final userId = authProvider.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reminders & Notifications'),
        actions: [
          if (notificationProvider.unreadCount > 0 && userId != null)
            TextButton(
              onPressed: () {
                notificationProvider.markAllAsRead(userId);
              },
              child: const Text('Mark all as read', style: TextStyle(color: AppColors.blue)),
            ),
        ],
      ),
      body: SafeArea(
        child: notificationProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notificationProvider.notifications.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'No Notifications',
                    description: 'You have no active reminders or notifications.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notificationProvider.notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notificationProvider.notifications[index];
                      final isUnread = notif.isRead == 0;

                      return InkWell(
                        onTap: () {
                          if (userId != null && notif.id != null) {
                            notificationProvider.markAsRead(notif.id!, userId);
                          }
                          Navigator.pushNamed(context, RouteNames.myVisits);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUnread ? AppColors.white : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isUnread ? AppColors.blue : AppColors.line,
                              width: isUnread ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.tint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_active_outlined, color: AppColors.blue, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.body,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
