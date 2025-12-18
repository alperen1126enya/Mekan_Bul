import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/auth_provider.dart';
import '../providers/mekan_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../widgets/page_wrapper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getNotifications(
        authProvider.currentUser!.id!,
      );
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    
    await _notificationService.markAsRead(notification.id!);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) return;

    await _notificationService.markAllAsRead(authProvider.currentUser!.id!);
    _loadNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm bildirimler okundu olarak işaretlendi'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    await _notificationService.deleteNotification(notification.id!);
    _loadNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim silindi'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _onNotificationTap(AppNotification notification) {
    _markAsRead(notification);

    // Navigate based on notification type
    if (notification.referenceId != null) {
      switch (notification.type) {
        case 'favorite_update':
        case 'comment_reply':
        case 'new_place':
          final authProvider = context.read<AuthProvider>();
          context.read<MekanProvider>().selectMekan(
                notification.referenceId!,
                userId: authProvider.currentUser?.id,
              );
          Navigator.pushNamed(context, AppConstants.mekanDetailRoute);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return PageWrapper(
      showBackButton: true,
      title: 'Bildirimler',
      actions: [
        if (_notifications.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: _markAllAsRead,
            tooltip: 'Tümünü Okundu İşaretle',
          ),
      ],
      child: !authProvider.isLoggedIn
          ? _buildLoginRequired()
          : _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giriş Yapın',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bildirimleri görmek için giriş yapmalısınız.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppConstants.loginRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Giriş Yap', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.textMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bildirim Yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Henüz hiç bildiriminiz bulunmuyor.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.surface : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              color: AppColors.textPrimary,
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
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
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

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'favorite_update':
        return Icons.favorite_rounded;
      case 'comment_reply':
        return Icons.chat_bubble_rounded;
      case 'new_place':
        return Icons.place_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'favorite_update':
        return AppColors.accent;
      case 'comment_reply':
        return AppColors.primary;
      case 'new_place':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Az önce';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
