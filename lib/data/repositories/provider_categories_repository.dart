import '../../models/provider/provider_category.dart';
import '../../services/provider_categories_api_service.dart';

/// Thin pass-through to [ProviderCategoriesApiService] — no merging with any
/// on-device store, matching `ServiceCatalogRepository`/`ServiceTitleRepository`.
class ProviderCategoriesRepository {
  ProviderCategoriesRepository({ProviderCategoriesApiService? apiService}) : _apiService = apiService ?? ProviderCategoriesApiService();

  final ProviderCategoriesApiService _apiService;

  Future<List<ProviderCategory>> fetchCategories(int providerUid) => _apiService.fetchCategories(providerUid);

  Future<List<ProviderCategory>> replaceCategories(int providerUid, {required List<int> categoryIds, required int primaryCategoryId}) {
    return _apiService.replaceCategories(providerUid, categoryIds: categoryIds, primaryCategoryId: primaryCategoryId);
  }
}
