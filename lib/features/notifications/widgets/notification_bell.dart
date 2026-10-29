import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/notifications_controller.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = context.watch<NotificationsController>().unreadCount;

    return IconButton(
      tooltip: 'الإشعارات',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        child: Icon(
          unread > 0 ? Icons.notifications_active : Icons.notifications_none,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onPressed: () => context.push('/notifications'),
    );
  }
}
