import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/reverse_geocode_result.dart';
import '../utils/constants.dart';

class GeocodingApiService {
  Future<ReverseGeocodeResult> reverseGeocode({required double latitude, required double longitude}) async {
    final response = await http
        .get(Uri.parse('$kApiBaseUrl/geocoding/reverse?lat=$latitude&lng=$longitude'))
        .timeout(kApiTimeout);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Failed to resolve address (status ${response.statusCode})');
    }

    final success = json['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      throw Exception(json['message'] as String? ?? 'Unable to resolve address for the given coordinates.');
    }
    return ReverseGeocodeResult.fromJson(json['data'] as Map<String, dynamic>);
  }
}
