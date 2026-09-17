class RecipientModel {
  final String id;
  final String customUserId;
  final String firstName;
  final String lastName;
  final String nic;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String district;
  final double? latitude;
  final double? longitude;
  final String timeZone;
  final String language;
  final String? createdAt;
  final String? updatedAt;

  RecipientModel({
    required this.id,
    required this.customUserId,
    required this.firstName,
    required this.lastName,
    required this.nic,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.district,
    this.latitude,
    this.longitude,
    required this.timeZone,
    required this.language,
    this.createdAt,
    this.updatedAt,
  });

  factory RecipientModel.fromJson(Map<String, dynamic> json) {
    return RecipientModel(
      id: json['id']?.toString() ?? '',
      customUserId: json['customUserId']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      nic: json['nic'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timeZone: json['timeZone'] ?? '',
      language: json['language'] ?? '',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customUserId': customUserId,
      'firstName': firstName,
      'lastName': lastName,
      'nic': nic,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      'city': city,
      'district': district,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'timeZone': timeZone,
      'language': language,
    };
  }
}
