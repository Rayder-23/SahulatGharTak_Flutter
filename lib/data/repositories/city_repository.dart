import '../../services/city_api_service.dart';

/// Thin pass-through over `CityApiService` — single call, no
/// merging/filtering — exists to give `CityProvider` an injectable
/// data-source seam for testing.
class CityRepository {
  CityRepository({CityApiService? apiService}) : _apiService = apiService ?? CityApiService();

  final CityApiService _apiService;

  Future<List<String>> fetchCities() => _apiService.fetchCities();
}
