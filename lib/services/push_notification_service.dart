import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/push_event.dart';
import '../utils/update_block.dart';

/// Runs in its own isolate while the app is backgrounded/terminated. The OS
/// already renders the banner for notification messages, so this stays
/// data-only (no UI, no provider access).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    UpdateBlock.persistFromData(message.data);

/// The only place that touches `FirebaseMessaging` / local notifications.
/// Screens and providers consume [events] and never import Firebase.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _accent = Color(0xFF003366);
  static const _fallbackChannelId = 'booking_updates_v2';

  // An Android channel's sound is fixed once the channel exists on a device,
  // so the sounded channels are new `_v2` ids and the earlier silent ones are
  // deleted in init(). If a sound ever changes, mint a new id again.
  // high_importance_channel stays: it is the manifest default and what the
  // backend uses until Notifications:AndroidChannelsEnabled is switched on.
  static const _channels = [
    AndroidNotificationChannel(
      'high_importance_channel',
      'Important notifications',
      description: 'Job requests, bookings and request updates.',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'job_requests_v2',
      'Job requests',
      description: 'New job requests for providers.',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('job_request'),
    ),
    AndroidNotificationChannel(
      'booking_updates_v2',
      'Booking updates',
      description: 'Accepted, started, completed and cancelled bookings.',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('booking_update'),
    ),
    AndroidNotificationChannel(
      'announcements_v2',
      'Announcements',
      description: 'App updates and announcements.',
      importance: Importance.defaultImportance,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('announcement'),
    ),
  ];

  // Silent channels from the earlier build.
  static const _retiredChannelIds = [
    'job_requests',
    'booking_updates',
    'announcements',
  ];

  /// Unique ids for pushes with neither booking_id nor request_id.
  int _anonymousCounter = 0;

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
        android: AndroidInitializationSettings('ic_notification'),
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

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final id in _retiredChannelIds) {
      await androidPlugin?.deleteNotificationChannel(channelId: id);
    }
    for (final channel in _channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    // iOS shows its own banner for foreground notification messages.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      updateBlock.record(m.data, message: m.notification?.body);
      _events.add(PushEvent.fromData(m.data, fromTap: true));
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      updateBlock.record(initial.data, message: initial.notification?.body);
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
    updateBlock.record(message.data, message: message.notification?.body);
    // Silent admin release: nothing to show, route or count.
    if (message.data['type'] == 'app_unblock') return;
    _events.add(PushEvent.fromData(message.data));

    final notification = message.notification;
    if (notification == null || !Platform.isAndroid) return;

    final data = message.data;
    // Accept the backend's id with or without the _v2 suffix.
    final requested = (data['channel_id'] ?? '').toString();
    final wanted = requested.endsWith('_v2') ? requested : '${requested}_v2';
    final channel = _channels.firstWhere(
      (c) => c.id == requested || c.id == wanted,
      orElse: () => _channels.firstWhere((c) => c.id == _fallbackChannelId),
    );
    // Event time from the backend, never the time this device received it.
    final sentAt = DateTime.tryParse(data['sent_at'] ?? '');

    // Android replaces a notification only when BOTH tag and id match. The
    // system draws background pushes with the backend's tag and id 0, so a
    // keyed foreground banner must use that same tag and id 0, otherwise a
    // background push and a foreground one for the same booking never merge.
    // Pushes with no key get a unique id and no tag, so they just stack.
    final stackKey = _stackKey(data);

    _local.show(
      id: stackKey != null ? 0 : 0x40000000 + (_anonymousCounter++ & 0xFFFFFF),
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          playSound: channel.playSound,
          sound: channel.sound,
          priority: channel.importance == Importance.high
              ? Priority.high
              : Priority.defaultPriority,
          tag: stackKey,
          icon: 'ic_notification',
          color: _accent,
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
          when: sentAt?.millisecondsSinceEpoch,
          showWhen: sentAt != null,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  /// The stacking key the backend also sends as the Android tag on
  /// background pushes: `booking-{id}`, else `request-{id}`, else none.
  static String? _stackKey(Map<String, dynamic> data) {
    final booking = (data['booking_id'] ?? '').toString();
    final request = (data['request_id'] ?? '').toString();
    if (booking.isNotEmpty) return 'booking-$booking';
    if (request.isNotEmpty) return 'request-$request';
    return null;
  }
}
