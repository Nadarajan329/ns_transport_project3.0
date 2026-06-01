import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/core/constants/app_colors.dart';
import 'package:ns_transport/providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: notificationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading notifications: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final dateFormat = DateFormat('MMM d, h:mm a');
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                tileColor: notification.isRead 
                    ? Colors.transparent 
                    : (isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.05)),
                leading: CircleAvatar(
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(
                    _getIconForType(notification.type),
                    color: notification.isRead 
                        ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                        : AppColors.primary,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: GoogleFonts.inter(
                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(notification.createdAt.toLocal()),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (!notification.isRead) {
                    ref.read(notificationProvider.notifier).markAsRead(notification.id);
                  }
                  // Optionally navigate based on notification.type or relatedId
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'trip_submitted':
        return Icons.local_shipping;
      case 'trip_approved':
        return Icons.check_circle;
      case 'trip_rejected':
        return Icons.cancel;
      case 'salary_updated':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }
}
