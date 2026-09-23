class ReverseGeocodeResult {
  final String displayName;
  final String road;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final double latitude;
  final double longitude;

  const ReverseGeocodeResult({
    required this.displayName,
    required this.road,
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      displayName: json['displayName'] as String? ?? '',
      road: json['road'] as String? ?? '',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
