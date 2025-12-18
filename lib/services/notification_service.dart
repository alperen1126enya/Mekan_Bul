import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _db = DatabaseHelper();
  
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    // This is handled in the app based on the payload
  }

  /// Check and request notification permission
  Future<bool> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mekanbul_channel',
      'Mekan Bul Bildirimleri',
      channelDescription: 'Mekan Bul uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Create and save a notification to database
  Future<AppNotification> createNotification({
    required int userId,
    required String title,
    required String body,
    required String type,
    int? referenceId,
    bool showPush = true,
  }) async {
    final notification = AppNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
    );

    final id = await _db.insert('notifications', notification.toMap());
    
    // Show push notification if requested
    if (showPush) {
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: '{"type": "$type", "referenceId": $referenceId}',
      );
    }

    return notification.copyWith(id: id);
  }

  /// Get all notifications for a user
  Future<List<AppNotification>> getNotifications(int userId) async {
    final results = await _db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => AppNotification.fromMap(map)).toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount(int userId) async {
    final results = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );

    return results.first['count'] as int;
  }

  /// Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    await _db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(int userId) async {
    await _db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    await _db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(int userId) async {
    await _db.delete(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Convenience methods for specific notification types

  /// Send notification when a favorite mekan is updated
  Future<void> notifyFavoriteUpdate({
    required int userId,
    required int mekanId,
    required String mekanName,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Favori Mekan Güncellendi',
      body: '$mekanName hakkında yeni bilgiler var!',
      type: 'favorite_update',
      referenceId: mekanId,
    );
  }

  /// Send notification when someone replies to a comment
  Future<void> notifyCommentReply({
    required int userId,
    required int mekanId,
    required String mekanName,
    required String replierName,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Yeni Yorum Yanıtı',
      body: '$replierName, $mekanName yorumunuza yanıt verdi.',
      type: 'comment_reply',
      referenceId: mekanId,
    );
  }

  /// Send notification for new place in user's preferred category
  Future<void> notifyNewPlace({
    required int userId,
    required int mekanId,
    required String mekanName,
    required String category,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Yeni Mekan Eklendi',
      body: 'Sevdiğiniz kategoride yeni bir mekan: $mekanName',
      type: 'new_place',
      referenceId: mekanId,
    );
  }
}
