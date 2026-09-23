class ClientAddress {
  final int uid;
  final int clientUid;
  final String addressTitle;
  final String fullAddress;
  final String area;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool hasLocation;

  const ClientAddress({
    required this.uid,
    required this.clientUid,
    required this.addressTitle,
    required this.fullAddress,
    required this.area,
    required this.city,
    this.latitude,
    this.longitude,
    this.hasLocation = false,
  });

  factory ClientAddress.fromJson(Map<String, dynamic> json) {
    return ClientAddress(
      uid: json['uid'] as int,
      clientUid: json['clientUid'] as int,
      addressTitle: json['addressTitle'] as String? ?? '',
      fullAddress: json['fullAddress'] as String? ?? '',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hasLocation: json['hasLocation'] as bool? ?? false,
    );
  }
}
