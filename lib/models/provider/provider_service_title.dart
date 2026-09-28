/// One of a provider's optionally-declared service titles, scoped to a
/// category they already hold (see `GET`/`PUT
/// /api/providers/{providerUid}/service-titles`).
class ProviderServiceTitle {
  final int serviceTitleUid;
  final String title;
  final int categoryUid;
  final String categoryName;

  const ProviderServiceTitle({
    required this.serviceTitleUid,
    required this.title,
    required this.categoryUid,
    required this.categoryName,
  });

  factory ProviderServiceTitle.fromJson(Map<String, dynamic> json) {
    return ProviderServiceTitle(
      serviceTitleUid: json['serviceTitleUid'] as int,
      title: json['title'] as String,
      categoryUid: json['categoryUid'] as int,
      categoryName: json['categoryName'] as String,
    );
  }
}
