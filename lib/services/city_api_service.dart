import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class CityApiService {
  Future<List<String>> fetchCities() async {
    final uri = Uri.parse('$kApiBaseUrl/cities');

    final response = await http.get(uri).timeout(kApiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load cities (status ${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<String>();
  }
}
