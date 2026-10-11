class VolunteerDelivery {
  final String id;
  final String? volunteerId;
  final String donorId;
  final String recipientId;
  final String foodItem;
  final double foodQuantityKg;
  final DateTime? foodExpiryDate;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? pickupAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String? dropoffAddress;
  final String status;
  final String? rejectionReason;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DonorContact? donor;
  final RecipientContact? recipient;
  final double? distanceKm;
  final double? expiryUrgencyHours;

  const VolunteerDelivery({
    required this.id,
    this.volunteerId,
    required this.donorId,
    required this.recipientId,
    required this.foodItem,
    required this.foodQuantityKg,
    this.foodExpiryDate,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupAddress,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.dropoffAddress,
    required this.status,
    this.rejectionReason,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.rejectedAt,
    this.createdAt,
    this.updatedAt,
    this.donor,
    this.recipient,
    this.distanceKm,
    this.expiryUrgencyHours,
  });

  factory VolunteerDelivery.fromJson(Map<String, dynamic> json) {
    return VolunteerDelivery(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      volunteerId: json['volunteerId']?.toString(),
      donorId: json['donorId']?.toString() ?? '',
      recipientId: json['recipientId']?.toString() ?? '',
      foodItem: json['foodItem']?.toString() ?? 'Food item',
      foodQuantityKg: _toDouble(json['foodQuantityKg']) ?? 0,
      foodExpiryDate: _toDate(json['foodExpiryDate']),
      pickupLatitude: _toDouble(json['pickupLatitude']),
      pickupLongitude: _toDouble(json['pickupLongitude']),
      pickupAddress: json['pickupAddress']?.toString(),
      dropoffLatitude: _toDouble(json['dropoffLatitude']),
      dropoffLongitude: _toDouble(json['dropoffLongitude']),
      dropoffAddress: json['dropoffAddress']?.toString(),
      status: json['status']?.toString() ?? 'PENDING_ASSIGNMENT',
      rejectionReason: json['rejectionReason']?.toString(),
      acceptedAt: _toDate(json['acceptedAt']),
      pickedUpAt: _toDate(json['pickedUpAt']),
      deliveredAt: _toDate(json['deliveredAt']),
      rejectedAt: _toDate(json['rejectedAt']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
      donor: json['donor'] is Map<String, dynamic>
          ? DonorContact.fromJson(
              json['donor'] as Map<String, dynamic>,
            )
          : null,
      recipient: json['recipient'] is Map<String, dynamic>
          ? RecipientContact.fromJson(
              json['recipient'] as Map<String, dynamic>,
            )
          : null,
      distanceKm: _toDouble(json['distanceKm']),
      expiryUrgencyHours: _toDouble(json['expiryUrgencyHours']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}

class DonorContact {
  final String email;

  const DonorContact({
    required this.email,
  });

  factory DonorContact.fromJson(Map<String, dynamic> json) {
    return DonorContact(
      email: json['email']?.toString() ?? '',
    );
  }
}

class RecipientContact {
  final String name;
  final String phoneNumber;
  final String deliveryAddress;

  const RecipientContact({
    required this.name,
    required this.phoneNumber,
    required this.deliveryAddress,
  });

  factory RecipientContact.fromJson(Map<String, dynamic> json) {
    return RecipientContact(
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
    );
  }
}