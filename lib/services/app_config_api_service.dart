import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_config.dart';
import '../utils/constants.dart';

class AppConfigApiService {
  /// [platform] is `android` or `ios`. The response is a bare snake_case
  /// object, not the `ApiResponse` envelope.
  Future<AppConfig> fetchConfig(String platform) async {
    final response = await http
        .get(Uri.parse('$kApiBaseUrl/v1/app/config')
            .replace(queryParameters: {'platform': platform}))
        .timeout(kApiTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Failed to load app config (status ${response.statusCode})');
    }
    return AppConfig.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
