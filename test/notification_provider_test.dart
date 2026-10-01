import 'package:flutter_test/flutter_test.dart';
import 'package:sahulat_ghar_tak/data/repositories/notification_repository.dart';
import 'package:sahulat_ghar_tak/models/app_notification.dart';
import 'package:sahulat_ghar_tak/models/push_event.dart';
import 'package:sahulat_ghar_tak/providers/notification_provider.dart';
import 'package:sahulat_ghar_tak/services/notification_api_service.dart';

AppNotification _n(int id, {bool read = false}) => AppNotification(
      id: id,
      userType: 'Client',
      type: 'booking_accepted',
      title: 't$id',
      body: 'b',
      screen: 'request_details',
      bookingUid: null,
      requestUid: 5,
      isRead: read,
      createdAt: DateTime.utc(2026, 10, 1),
    );

class _FakeApi extends NotificationApiService {
  List<AppNotification> all = [for (var i = 1; i <= 5; i++) _n(i)];
  bool failMarkRead = false;
  final markedRead = <int>[];

  @override
  Future<NotificationPage> fetchInbox({required int userId, required String userType, int page = 1, int pageSize = 20}) async {
    final start = (page - 1) * pageSize;
    final items = all.skip(start).take(pageSize).toList();
    return NotificationPage(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: all.length,
      unreadCount: all.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<int> fetchUnreadCount({required int userId, required String userType}) async =>
      all.where((n) => !n.isRead).length;

  @override
  Future<void> markRead({required int id, required int userId}) async {
    if (failMarkRead) throw Exception('boom');
    markedRead.add(id);
  }

  @override
  Future<void> markAllRead({required int userId, required String userType}) async {
    all = all.map((n) => n.copyWith(isRead: true)).toList();
  }
}

void main() {
  late _FakeApi api;
  late NotificationProvider provider;

  setUp(() {
    api = _FakeApi();
    provider = NotificationProvider(repository: NotificationRepository(apiService: api), pageSize: 2);
  });

  test('bind loads the badge and loadInbox paginates', () async {
    provider.bind(userId: 1, userType: 'Client');
    await Future<void>.delayed(Duration.zero);
    expect(provider.unreadCount, 5);

    await provider.loadInbox();
    expect(provider.items.length, 2);
    expect(provider.hasMore, isTrue);

    await provider.loadMore();
    await provider.loadMore();
    expect(provider.items.length, 5);
    expect(provider.hasMore, isFalse);
  });

  test('markRead is optimistic and rolls back on failure', () async {
    provider.bind(userId: 1, userType: 'Client');
    await provider.loadInbox();
    final before = provider.unreadCount;

    await provider.markRead(1);
    expect(provider.items.first.isRead, isTrue);
    expect(provider.unreadCount, before - 1);

    api.failMarkRead = true;
    await provider.markRead(2);
    expect(provider.items[1].isRead, isFalse);
    expect(provider.unreadCount, before - 1);
  });

  test('markAllRead zeroes the badge and clear resets state', () async {
    provider.bind(userId: 1, userType: 'Client');
    await provider.loadInbox();
    expect(await provider.markAllRead(), isTrue);
    expect(provider.unreadCount, 0);
    expect(provider.items.every((n) => n.isRead), isTrue);

    provider.clear();
    expect(provider.items, isEmpty);
    expect(provider.isBound, isFalse);
  });

  test('AppNotification.fromJson maps nulls and UTC time', () {
    final n = AppNotification.fromJson({
      'id': 3,
      'userType': 'Provider',
      'type': 'job_assigned',
      'title': 'x',
      'body': 'y',
      'screen': 'provider_job_requests',
      'bookingUid': 88,
      'requestUid': null,
      'isRead': false,
      'createdAt': '2026-10-01T09:30:12.1Z',
    });
    expect(n.bookingUid, 88);
    expect(n.requestUid, isNull);
    expect(n.createdAt.isUtc, isTrue);
  });

  test('PushEvent.fromData turns empty strings into null ids', () {
    final e = PushEvent.fromData({
      'type': 'job_assigned',
      'screen': 'provider_job_requests',
      'booking_id': '12',
      'request_id': '',
      'notification_id': '',
    });
    expect(e.bookingId, 12);
    expect(e.requestId, isNull);
    expect(e.notificationId, isNull);
    expect(e.refreshesLists, isTrue);
  });
}
