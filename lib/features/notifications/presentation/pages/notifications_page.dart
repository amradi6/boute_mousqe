import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  List<NotificationEntity> _notifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير موجود');

      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final items = (data as List).map((n) => NotificationEntity(
            id: n['id'] as String,
            userId: userId,
            title: n['title'] as String,
            body: n['body'] as String,
            type: n['type'] as String? ?? 'general',
            isRead: n['is_read'] as bool? ?? false,
            createdAt: DateTime.parse(n['created_at'] as String),
          )).toList();

      setState(() {
        _notifications = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);

    setState(() {
      final n = _notifications[index];
      _notifications[index] = NotificationEntity(
        id: n.id,
        userId: n.userId,
        title: n.title,
        body: n.body,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
      );
    });
  }

  Future<void> _markAllRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.notifications),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                AppStrings.markAllRead,
                style: AppTypography.labelSmall.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadNotifications)
              : _notifications.isEmpty
                  ? const AppEmptyWidget(
                      message: AppStrings.noNotifications,
                      icon: Icons.notifications_off_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          return _NotificationCard(
                            notification: n,
                            onTap: () => !n.isRead ? _markAsRead(n.id, i) : null,
                          ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideX(begin: 0.1);
                        },
                      ),
                    ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;

  const _NotificationCard({required this.notification, this.onTap});

  IconData get _icon => switch (notification.type) {
        'attendance' => Icons.calendar_today_outlined,
        'evaluation' => Icons.star_outline_rounded,
        'lesson' => Icons.book_outlined,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead ? AppColors.divider : AppColors.primary.withAlpha(60),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.surfaceVariant
                    : AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: notification.isRead ? AppColors.textSecondary : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.timeAgo,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
