import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../application/notification_providers.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Aucune notification.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _NotificationTile(items[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.notification);

  final AppNotification notification;

  IconData get _icon => switch (notification.kind) {
        NotificationKind.mint => Icons.verified_outlined,
        NotificationKind.transfer => Icons.swap_horiz,
        NotificationKind.system => Icons.notifications_none,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.read
            ? AppColors.background
            : AppColors.primary.withOpacity(0.15),
        child: Icon(_icon, color: AppColors.primary),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Text(notification.body),
      trailing: Text(
        DateFormat('dd/MM').format(notification.createdAt),
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      isThreeLine: true,
    );
  }
}
