import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider/provider_service_title.dart';
import '../utils/constants.dart';

class ProviderServiceTitlesApiService {
  Future<List<ProviderServiceTitle>> fetchServiceTitles(int providerUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/providers/$providerUid/service-titles')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load services');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ProviderServiceTitle.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ProviderServiceTitle>> replaceServiceTitles(
    int providerUid, {
    required List<int> serviceTitleIds,
  }) async {
    final response = await http
        .put(
          Uri.parse('$kApiBaseUrl/providers/$providerUid/service-titles'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'serviceTitleIds': serviceTitleIds}),
        )
        .timeout(kApiTimeout);

    final json = _decode(response, 'Failed to update services');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ProviderServiceTitle.fromJson(item as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _decode(http.Response response, String errorPrefix) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('$errorPrefix (status ${response.statusCode})');
    }

    final success = json['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      throw Exception(json['message'] as String? ?? errorPrefix);
    }
    return json;
  }
}
