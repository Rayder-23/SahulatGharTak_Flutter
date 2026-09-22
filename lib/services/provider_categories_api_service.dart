import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider/provider_category.dart';
import '../utils/constants.dart';

class ProviderCategoriesApiService {
  Future<List<ProviderCategory>> fetchCategories(int providerUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/providers/$providerUid/categories')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load categories');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ProviderCategory.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ProviderCategory>> replaceCategories(
    int providerUid, {
    required List<int> categoryIds,
    required int primaryCategoryId,
  }) async {
    final response = await http
        .put(
          Uri.parse('$kApiBaseUrl/providers/$providerUid/categories'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'categoryIds': categoryIds,
            'primaryCategoryId': primaryCategoryId,
          }),
        )
        .timeout(kApiTimeout);

    final json = _decode(response, 'Failed to update categories');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ProviderCategory.fromJson(item as Map<String, dynamic>)).toList();
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
