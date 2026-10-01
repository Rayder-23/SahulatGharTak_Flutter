/// A decoded FCM data payload (all values arrive as strings, empty when not
/// applicable - see `api.txt` "Push payload contract").
class PushEvent {
  final String type;
  final String screen;
  final int? bookingId;
  final int? requestId;
  final int? notificationId;

  /// True when the user tapped the notification; false when it merely arrived
  /// while the app was in the foreground.
  final bool fromTap;

  const PushEvent({
    required this.type,
    required this.screen,
    this.bookingId,
    this.requestId,
    this.notificationId,
    this.fromTap = false,
  });

  factory PushEvent.fromData(Map<String, dynamic> data,
          {bool fromTap = false}) =>
      PushEvent(
        type: data['type']?.toString() ?? '',
        screen: data['screen']?.toString() ?? '',
        bookingId: int.tryParse(data['booking_id']?.toString() ?? ''),
        requestId: int.tryParse(data['request_id']?.toString() ?? ''),
        notificationId: int.tryParse(data['notification_id']?.toString() ?? ''),
        fromTap: fromTap,
      );

  PushEvent asTap() => PushEvent(
        type: type,
        screen: screen,
        bookingId: bookingId,
        requestId: requestId,
        notificationId: notificationId,
        fromTap: true,
      );

  /// Events after which cached booking/request lists may be stale.
  bool get refreshesLists => const {
        'job_assigned',
        'booking_accepted',
        'job_unavailable',
        'provider_reassigning',
        'booking_cancelled',
        'job_started',
        'job_completed',
      }.contains(type);
}
