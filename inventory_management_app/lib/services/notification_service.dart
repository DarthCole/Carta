import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  Future<void> showRestockAlert(String storeName, String productName, int quantity) async {
    const androidDetails = AndroidNotificationDetails(
      'restock_channel',
      'Restock Reminders',
      channelDescription: 'Notifications for low stock items',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Low Stock Alert - $storeName',
      '$productName has only $quantity units left. Time to restock!',
      details,
    );
  }

  Future<void> showVerificationResult(String productName, bool verified) async {
    const androidDetails = AndroidNotificationDetails(
      'verification_channel',
      'Product Verification',
      channelDescription: 'Product authenticity verification results',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);

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
