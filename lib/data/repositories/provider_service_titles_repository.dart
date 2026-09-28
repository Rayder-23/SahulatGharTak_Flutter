import '../../models/provider/provider_service_title.dart';
import '../../services/provider_service_titles_api_service.dart';

/// Thin pass-through to [ProviderServiceTitlesApiService] — no merging with
/// any on-device store, matching `ProviderCategoriesRepository`.
class ProviderServiceTitlesRepository {
  ProviderServiceTitlesRepository({ProviderServiceTitlesApiService? apiService}) : _apiService = apiService ?? ProviderServiceTitlesApiService();

  final ProviderServiceTitlesApiService _apiService;

  Future<List<ProviderServiceTitle>> fetchServiceTitles(int providerUid) => _apiService.fetchServiceTitles(providerUid);

  Future<List<ProviderServiceTitle>> replaceServiceTitles(int providerUid, {required List<int> serviceTitleIds}) {
    return _apiService.replaceServiceTitles(providerUid, serviceTitleIds: serviceTitleIds);
  }
}
