class ServiceTitle {
  final int id;
  final int categoryId;
  final String categoryName;
  final String title;
  final String? description;
  final double? basePrice;
  final DateTime createdOn;

  const ServiceTitle({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.createdOn,
  });

  factory ServiceTitle.fromJson(Map<String, dynamic> json) {
    return ServiceTitle(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      createdOn: DateTime.parse(json['createdOn'] as String),
    );
  }
}
