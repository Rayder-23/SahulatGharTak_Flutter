import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import '../utils/constants.dart';

/// Device-token registration and the notification inbox. `userId` is always
/// the login id (`AuthData.userId`), not clientUid/providerUid. These
/// endpoints are anonymous today and will gain a Bearer header later - keep
/// that change confined to [_headers].
class NotificationApiService {
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<void> registerToken({
    required int userId,
    required String userType,
    required String deviceToken,
    required String platform,
  }) async {
    final response = await http
        .post(
          Uri.parse('$kApiBaseUrl/notifications/register-token'),
          headers: _headers,
          body: jsonEncode({
            'userId': userId,
            'userType': userType,
            'deviceToken': deviceToken,
            'platform': platform,
          }),
        )
        .timeout(kApiTimeout);
    _decode(response, 'Failed to register device');
  }

  Future<void> unregisterToken(String deviceToken) async {
    final response = await http
        .post(
          Uri.parse('$kApiBaseUrl/notifications/unregister-token'),
          headers: _headers,
          body: jsonEncode({'deviceToken': deviceToken}),
        )
        .timeout(kApiTimeout);
    _decode(response, 'Failed to unregister device');
  }

  Future<NotificationPage> fetchInbox({
    required int userId,
    required String userType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri =
        Uri.parse('$kApiBaseUrl/notifications').replace(queryParameters: {
      'userId': '$userId',
      'userType': userType,
      'page': '$page',
      'pageSize': '$pageSize',
    });
    final response =
        await http.get(uri, headers: _headers).timeout(kApiTimeout);
    final json = _decode(response, 'Failed to load notifications');
    return NotificationPage.fromJson(
        json['data'] as Map<String, dynamic>? ?? {});
  }

  Future<int> fetchUnreadCount(
      {required int userId, required String userType}) async {
    final uri = Uri.parse('$kApiBaseUrl/notifications/unread-count')
        .replace(queryParameters: {'userId': '$userId', 'userType': userType});
    final response =
        await http.get(uri, headers: _headers).timeout(kApiTimeout);
    final json = _decode(response, 'Failed to load unread count');
    return (json['data'] as Map<String, dynamic>?)?['unreadCount'] as int? ?? 0;
  }

  Future<void> markRead({required int id, required int userId}) async {
    final response = await http
        .post(
          Uri.parse('$kApiBaseUrl/notifications/$id/read'),
          headers: _headers,
          body: jsonEncode({'userId': userId}),
        )
        .timeout(kApiTimeout);
    _decode(response, 'Failed to mark notification as read');
  }

  Future<void> markAllRead(
      {required int userId, required String userType}) async {
    final response = await http
        .post(
          Uri.parse('$kApiBaseUrl/notifications/read-all'),
          headers: _headers,
          body: jsonEncode({'userId': userId, 'userType': userType}),
        )
        .timeout(kApiTimeout);
    _decode(response, 'Failed to mark notifications as read');
  }

  Map<String, dynamic> _decode(http.Response response, String errorPrefix) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('$errorPrefix (status ${response.statusCode})');
    }

    final success = json['success'] as bool? ??
        (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      throw Exception(json['message'] as String? ?? errorPrefix);
    }
    return json;
  }
}
