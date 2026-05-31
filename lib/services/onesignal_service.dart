import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';
import '../providers/admin_provider.dart';

/// OneSignalService
///
/// Architecture:
///   Web buyer uploads proof → Laravel sets status to PENDING_APPROVAL
///   → Laravel calls OneSignal REST API (POST /v1/notifications)
///   → OneSignal → FCM pipe → Android device
///   → This service intercepts and plays nuclear_alarm sound.
///
/// Flutter does NOT poll Laravel. It only listens to OneSignal push events.
class OneSignalService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  OneSignalService._internal();
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;

  static final String _appId = dotenv.maybeGet('ONESIGNAL_APP_ID') ?? 'c5e0718f-c589-4de3-82e5-48d396615c64';

  // ── flutter_local_notifications ────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel that matches the channel id sent by Laravel.
  /// 'transaction_alerts_channel' + 'nuclear_alarm' raw resource.
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
      icon: '@mipmap/launcher_icon',
    ),
  );

  // ── Public initializer ─────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[OneSignal] Initialization skipped on Web platform.');
      return;
    }

    try {
      // 1. Register the Android notification channel (creates it on the OS)
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      await _fln.initialize(const InitializationSettings(android: androidInit));
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 2. OneSignal SDK init
    if (kDebugMode) OneSignal.Debug.setLogLevel(OSLogLevel.debug);
    OneSignal.initialize(_appId);

    // 3. Request push permission (Android 13+ / iOS)
    await OneSignal.Notifications.requestPermission(true);

    // 4. Foreground push handler
    //    When app is open, OneSignal suppresses the native banner by default
    //    on Android. We intercept, suppress it, then show our own banner with
    //    the correct channel (which carries the nuclear_alarm sound).
    OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
      // Prevent the default OneSignal display so we control the channel
      event.preventDefault();

      final OSNotification notif = event.notification;
      final String title =
          notif.title ?? 'Pembayaran Baru';
      final String body =
          notif.body ?? 'Ada bukti pembayaran yang perlu diverifikasi.';

      // Show via flutter_local_notifications → uses transaction_alerts_channel
      // → OS plays nuclear_alarm.mp3 automatically via the channel config
      await _fln.show(
        notif.notificationId.hashCode,
        title,
        body,
        _notifDetails,
      );

      debugPrint('[OneSignal] Foreground notification displayed: $title');

      // Play local placeholder sound for new payments
      AudioPlayer().play(AssetSource('sounds/payment_in.mp3'));

      // Auto-refresh transaction list via the global navigator key
      if (navigatorKey.currentContext case final context?) {
        // ignore: use_build_context_synchronously
        context.read<AdminProvider>().fetchPendingTransactions();
      }
    });

    // 5. Tap / click handler (app opened from notification)
    OneSignal.Notifications.addClickListener((event) {
      debugPrint(
          '[OneSignal] Notification tapped: ${event.notification.jsonRepresentation()}');
      // Navigate to transaction list or show a dialog here if needed.
    });
    } catch (e) {
      debugPrint('[OneSignal] Initialization error: $e');
    }
  }
}
