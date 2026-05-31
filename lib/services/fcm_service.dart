import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/admin_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Background message handler — MUST be a top-level function (not a class method)
// Called when the app is terminated or in the background.
// ──────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // No UI available here — just log or do silent work.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FcmService {
  // ── Singleton ───────────────────────────────────────────────────────────────
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  /// Android notification channel — must match what Laravel sends.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'transaction_alerts_channel',
    'Transaction Alerts',
    description: 'Peringatan pembayaran tiket baru masuk',
    importance: Importance.max,
    playSound: true,
  );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'transaction_alerts_channel',
      'Transaction Alerts',
      channelDescription: 'Peringatan pembayaran tiket baru masuk',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    ),
  );

  // ── Public initializer ──────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[FCM] Initialization skipped on Web platform.');
      return;
    }

    try {
      // 1. Register the Android notification channel on the OS
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _fln.initialize(const InitializationSettings(android: androidInit));
      
      final androidImplementation = _fln.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.createNotificationChannel(_channel);
      
      // Request permission specifically for flutter_local_notifications (Android 13+)
      await androidImplementation?.requestNotificationsPermission();

      // 2. Request notification permission (Android 13+ / iOS)
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // 3. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

      // 4. Subscribe to the 'admin_alerts' topic so Laravel can broadcast to all admins
      await _fcm.subscribeToTopic('admin_alerts');
      debugPrint('[FCM] Subscribed to topic: admin_alerts');

      // 5. Foreground message handler
      //    By default, FCM suppresses heads-up banners when the app is open.
      //    We intercept and show our own local notification with the correct channel.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final String title = message.notification?.title ?? 'Pembayaran Baru';
        final String body  = message.notification?.body  ??
            'Ada bukti pembayaran yang perlu diverifikasi.';

        debugPrint('[FCM] Foreground message: $title');

        // Show heads-up banner via flutter_local_notifications
        await _fln.show(
          message.hashCode,
          title,
          body,
          _notifDetails,
        );

        // Auto-refresh pending transactions in the provider
        if (navigatorKey.currentContext case final context?) {
          // ignore: use_build_context_synchronously
          context.read<AdminProvider>().fetchPendingTransactions();
        }
      });

      // 6. Tap / click handler (app opened from a notification tap)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Notification tapped: ${message.messageId}');
        // Navigate or show dialog here if needed.
      });

      // 7. Handle notification that launched the app from terminated state
      final RemoteMessage? initial = await _fcm.getInitialMessage();
      if (initial != null) {
        debugPrint('[FCM] App launched from notification: ${initial.messageId}');
      }

      // 8. Print FCM token (useful during development/testing)
      final String? token = await _fcm.getToken();
      debugPrint('[FCM] Device token: $token');

    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }
}
