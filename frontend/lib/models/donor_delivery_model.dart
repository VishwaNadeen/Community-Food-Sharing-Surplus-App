/// A delivery of the donor's food that a volunteer has accepted.
/// Built from GET /api/donors/deliveries.
class DonorDeliveryModel {
  final String id;
  final String status;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  final String foodItem;
  final double foodQuantityKg;
  final DateTime? foodExpiryDate;

  final String? pickupAddress;
  final String? dropoffAddress;
  final double? distanceKm;

  final DeliveryVolunteer? volunteer;
  final DeliveryRecipient? recipient;

  const DonorDeliveryModel({
    required this.id,
    required this.status,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.foodItem,
    required this.foodQuantityKg,
    this.foodExpiryDate,
    this.pickupAddress,
    this.dropoffAddress,
    this.distanceKm,
    this.volunteer,
    this.recipient,
  });

  /// Short reference shown to the donor, e.g. "#265C0D".
  String get reference =>
      '#${id.length > 6 ? id.substring(id.length - 6) : id}'.toUpperCase();

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static double? _number(dynamic value) =>
      value == null ? null : double.tryParse(value.toString());

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  factory DonorDeliveryModel.fromJson(Map<String, dynamic> json) {
    final food = _map(json['food']);
    final pickup = _map(json['pickup']);
    final dropoff = _map(json['dropoff']);

    return DonorDeliveryModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      acceptedAt: _date(json['acceptedAt']),
      pickedUpAt: _date(json['pickedUpAt']),
      deliveredAt: _date(json['deliveredAt']),
      foodItem: food['item']?.toString() ?? '',
      foodQuantityKg: _number(food['quantityKg']) ?? 0,
      foodExpiryDate: _date(food['expiryDate']),
      pickupAddress: pickup['address']?.toString(),
      dropoffAddress: dropoff['address']?.toString(),
      distanceKm: _number(json['distanceKm']),
      volunteer: json['volunteer'] is Map
          ? DeliveryVolunteer.fromJson(_map(json['volunteer']))
          : null,
      recipient: json['recipient'] is Map
          ? DeliveryRecipient.fromJson(_map(json['recipient']))
          : null,
    );
  }
}

class DeliveryVolunteer {
  final String volunteerId;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? email;
  final String? vehicleType;
  final String? vehicleNumber;

  const DeliveryVolunteer({
    required this.volunteerId,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.email,
    this.vehicleType,
    this.vehicleNumber,
  });

  String get fullName {
    final name = [firstName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
    return name.isEmpty ? 'Volunteer $volunteerId' : name;
  }

  /// "Car (ABC-1234)", "Car", or empty when unknown.
  String get vehicle {
    final type = vehicleType?.trim() ?? '';
    final number = vehicleNumber?.trim() ?? '';

    if (type.isEmpty) return number;
    if (number.isEmpty) return type;
    return '$type ($number)';
  }

  factory DeliveryVolunteer.fromJson(Map<String, dynamic> json) {
    return DeliveryVolunteer(
      volunteerId: json['volunteerId']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
    );
  }
}

class DeliveryRecipient {
  final String name;
  final String? city;
  final String? district;

  const DeliveryRecipient({required this.name, this.city, this.district});

  /// "Gunnepana, Kandy"
  String get area => [city, district]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(', ');

  factory DeliveryRecipient.fromJson(Map<String, dynamic> json) {
    return DeliveryRecipient(
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString(),
      district: json['district']?.toString(),
    );
  }
}
