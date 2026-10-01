import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/push_event.dart';

/// Runs in its own isolate while the app is backgrounded/terminated. The OS
/// already renders the banner for notification messages, so this stays
/// data-only (no UI, no provider access).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// The only place that touches `FirebaseMessaging` / local notifications.
/// Screens and providers consume [events] and never import Firebase.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _channelId = 'high_importance_channel';
  static const _channel = AndroidNotificationChannel(
    _channelId,
    'Important notifications',
    description: 'Job requests, bookings and request updates.',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();
  final _events = StreamController<PushEvent>.broadcast();
  bool _initialized = false;
  PushEvent? _initialEvent;

  /// Foreground arrivals (`fromTap == false`) and notification taps
  /// (`fromTap == true`).
  Stream<PushEvent> get events => _events.stream;

  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  String get platform => Platform.isIOS ? 'ios' : 'android';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _events.add(PushEvent.fromData(data, fromTap: true));
        } catch (_) {}
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // iOS shows its own banner for foreground notification messages.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _events.add(PushEvent.fromData(m.data, fromTap: true)));

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _initialEvent = PushEvent.fromData(initial.data, fromTap: true);
    }
  }

  /// The notification that cold-started the app, once. Route it only after
  /// the session has been resolved.
  PushEvent? takeInitialEvent() {
    final event = _initialEvent;
    _initialEvent = null;
    return event;
  }

  /// Asks for the iOS / Android 13+ notification permission. Safe to call
  /// repeatedly; the OS only prompts once.
  Future<bool> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    _events.add(PushEvent.fromData(message.data));

    final notification = message.notification;
    if (notification == null || !Platform.isAndroid) return;
    _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
