import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// managing local push notifications for the carta app.
///
/// implementing the singleton pattern to maintain a single notification
/// plugin instance. providing two notification channels: one for restock
/// alerts and one for product verification results. all notifications
/// are local and work fully offline.
class NotificationService {
  // singleton instance — ensuring consistent notification configuration
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // the flutter local notifications plugin instance
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// initialising the notification plugin with android-specific settings.
  /// using the app's launcher icon as the notification icon.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  /// showing a low-stock restock alert notification.
  /// displaying the store name, product name, and remaining quantity.
  /// using high importance and priority with sound and vibration enabled.
  Future<void> showRestockAlert(String storeName, String productName, int quantity) async {
    const androidDetails = AndroidNotificationDetails(
      'restock_channel', // channel id for restock notifications
      'Restock Reminders', // human-readable channel name
      channelDescription: 'Notifications for low stock items',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);

    // using timestamp-based id to avoid overwriting previous notifications
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Low Stock Alert - $storeName',
      '$productName has only $quantity units left. Time to restock!',
      details,
    );
  }

  /// showing a product verification result notification.
  /// indicating whether the scanned product passed or failed verification.
  Future<void> showVerificationResult(String productName, bool verified) async {
    const androidDetails = AndroidNotificationDetails(
      'verification_channel', // channel id for verification notifications
      'Product Verification', // human-readable channel name
      channelDescription: 'Product authenticity verification results',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);

    // using timestamp-based id to avoid overwriting previous notifications
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      verified ? 'Product Verified ✓' : 'Verification Failed ✗',
      verified
          ? '$productName has been verified as authentic.'
          : '$productName could not be verified. Check the product source.',
      details,
    );
  }
}
