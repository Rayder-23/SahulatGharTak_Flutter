/// One of a provider's assigned categories (Feature 9 - multi-category
/// support), returned by `GET`/`PUT /api/providers/{providerUid}/categories`.
class ProviderCategory {
  final int categoryUid;
  final String categoryName;
  final bool isPrimary;

  const ProviderCategory({required this.categoryUid, required this.categoryName, required this.isPrimary});

  factory ProviderCategory.fromJson(Map<String, dynamic> json) {
    return ProviderCategory(
      categoryUid: json['categoryUid'] as int,
      categoryName: json['categoryName'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}
