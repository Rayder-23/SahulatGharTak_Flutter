import 'package:flutter/material.dart';

import '../data/repositories/city_repository.dart';
import '../utils/api_error.dart';

class CityProvider extends ChangeNotifier {
  CityProvider({required CityRepository repository}) : _repository = repository;

  final CityRepository _repository;

  List<String> _cities = [];
  bool _isLoading = false;
  String? _error;

  List<String> get cities => List.unmodifiable(_cities);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCities() async {
    if (_cities.isNotEmpty || _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cities = await _repository.fetchCities();
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
