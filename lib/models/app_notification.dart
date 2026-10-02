/// One row of the user's notification inbox (`GET /api/notifications`).
class AppNotification {
  final int id;
  final String userType;
  final String type;
  final String title;
  final String body;
  final String screen;
  final int? bookingUid;
  final int? requestUid;
  final bool isRead;

  /// UTC instant (serialized with a `Z` suffix).
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userType,
    required this.type,
    required this.title,
    required this.body,
    required this.screen,
    required this.bookingUid,
    required this.requestUid,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        userType: json['userType'] as String? ?? '',
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        screen: json['screen'] as String? ?? '',
        bookingUid: json['bookingUid'] as int?,
        requestUid: json['requestUid'] as int?,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: _parseUtc(json['createdAt'] as String),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userType: userType,
        type: type,
        title: title,
        body: body,
        screen: screen,
        bookingUid: bookingUid,
        requestUid: requestUid,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

/// One page of the inbox plus the totals the server reports alongside it.
class NotificationPage {
  final List<AppNotification> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int unreadCount;

  const NotificationPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.unreadCount,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      NotificationPage(
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int? ?? 1,
        pageSize: json['pageSize'] as int? ?? 20,
        totalCount: json['totalCount'] as int? ?? 0,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

/// The API sends UTC with a `Z`; treat a zone-less value as UTC too so it is
/// never misread as device-local time.
DateTime _parseUtc(String value) {
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z');
}
