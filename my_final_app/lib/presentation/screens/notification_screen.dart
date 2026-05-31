import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart';
import '../providers/notification_notifier.dart';
import '../theme/notification_type_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_ext.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  NotificationCategory? _selectedCategory;

  List<AppNotification> _filtered(List<AppNotification> all) {
    if (_selectedCategory == null) return all;
    return all.where((n) => n.category == _selectedCategory).toList();
  }

  Map<String, List<AppNotification>> _groupByDate(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = <AppNotification>[];
    final yesterdayList = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final n in items) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        todayList.add(n);
      } else if (d == yesterday) {
        yesterdayList.add(n);
      } else {
        earlier.add(n);
      }
    }

    final result = <String, List<AppNotification>>{};
    if (todayList.isNotEmpty) result['TODAY'] = todayList;
    if (yesterdayList.isNotEmpty) result['YESTERDAY'] = yesterdayList;
    if (earlier.isNotEmpty) result['EARLIER'] = earlier;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final filtered = _filtered(notifications);
    final grouped = _groupByDate(filtered);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, unreadCount, notifier),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.appBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: filtered.isEmpty
                    ? _emptyState(context)
                    : _buildList(grouped, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int unreadCount,
    NotificationNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: notifier.markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _tab(null, 'All'),
          const SizedBox(width: 8),
          _tab(NotificationCategory.buyer, 'Buyer'),
          const SizedBox(width: 8),
          _tab(NotificationCategory.forYou, 'For You'),
          const SizedBox(width: 8),
          _tab(NotificationCategory.system, 'System'),
        ],
      ),
    );
  }

  Widget _tab(NotificationCategory? cat, String label) {
    final isActive = _selectedCategory == cat;
    return Semantics(
      button: true,
      label: 'Filter notifications: $label',
      selected: isActive,
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.orange
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    Map<String, List<AppNotification>> grouped,
    NotificationNotifier notifier,
  ) {
    // Flatten into a list of (header | notification) items for lazy rendering
    final items = <Object>[];
    for (final entry in grouped.entries) {
      items.add(entry.key); // String = section header
      items.addAll(entry.value);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
            child: Text(
              item,
              style: TextStyle(
                color: context.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          );
        }
        final n = item as AppNotification;
        return _NotificationCard(
          notification: n,
          onTap: () => notifier.markRead(n.id),
          onDelete: () => notifier.delete(n.id),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: context.secondaryText.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You're all caught up!",
            style: TextStyle(fontSize: 12, color: context.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCardBg = context.isDark
        ? const Color(0xFF2A1A10)
        : AppColors.unreadBg;

    return Semantics(
      button: true,
      label: 'Notification: ${notification.title}. ${notification.body}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead ? context.cardBg : unreadCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notification.isRead
                  ? context.border
                  : AppColors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: notification.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.primaryText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!notification.isRead) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Semantics(
                    button: true,
                    label: 'Delete notification',
                    child: GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: context.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
