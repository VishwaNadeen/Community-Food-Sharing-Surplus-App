import 'delivery_model.dart';

class VolunteerAvailability {
  final String status;
  final String? notes;

  const VolunteerAvailability({
    required this.status,
    this.notes,
  });

  bool get isAvailable => status == 'AVAILABLE';

  factory VolunteerAvailability.fromJson(
    Map<String, dynamic> json,
  ) {
    return VolunteerAvailability(
      status: json['status']?.toString() ?? 'UNAVAILABLE',
      notes: json['notes']?.toString(),
    );
  }
}

class VolunteerDashboardStats {
  final int completedDeliveries;
  final int activeDeliveries;
  final int totalDeliveries;
  final double totalFoodDeliveredKg;
  final double estimatedDistanceCoveredKm;
  final int communityImpactScore;

  const VolunteerDashboardStats({
    required this.completedDeliveries,
    required this.activeDeliveries,
    required this.totalDeliveries,
    required this.totalFoodDeliveredKg,
    required this.estimatedDistanceCoveredKm,
    required this.communityImpactScore,
  });

  factory VolunteerDashboardStats.fromJson(
    Map<String, dynamic> json,
  ) {
    return VolunteerDashboardStats(
      completedDeliveries: _toInt(
        json['completedDeliveries'],
      ),
      activeDeliveries: _toInt(
        json['activeDeliveries'],
      ),
      totalDeliveries: _toInt(
        json['totalDeliveries'],
      ),
      totalFoodDeliveredKg: _toDouble(
        json['totalFoodDeliveredKg'],
      ),
      estimatedDistanceCoveredKm: _toDouble(
        json['estimatedDistanceCoveredKm'],
      ),
      communityImpactScore: _toInt(
        json['communityImpactScore'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class DeliveryTrackingEntry {
  final String id;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? message;
  final DateTime? createdAt;

  const DeliveryTrackingEntry({
    required this.id,
    required this.status,
    this.latitude,
    this.longitude,
    this.message,
    this.createdAt,
  });

  factory DeliveryTrackingEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeliveryTrackingEntry(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      status: json['status']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      message: json['message']?.toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(
              json['createdAt'].toString(),
            ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }
}

class DeliveryProblem {
  final String id;
  final String problemType;
  final String description;
  final String status;
  final DateTime? createdAt;

  const DeliveryProblem({
    required this.id,
    required this.problemType,
    required this.description,
    required this.status,
    this.createdAt,
  });

  factory DeliveryProblem.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeliveryProblem(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      problemType:
          json['problemType']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      status:
          json['status']?.toString() ?? 'REPORTED',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(
              json['createdAt'].toString(),
            ),
    );
  }
}

class OptimizedVolunteerRoute {
  final List<VolunteerDelivery> deliveries;
  final double totalDistanceKm;
  final String? googleMapsUrl;

  const OptimizedVolunteerRoute({
    required this.deliveries,
    required this.totalDistanceKm,
    this.googleMapsUrl,
  });

  factory OptimizedVolunteerRoute.fromJson(
    Map<String, dynamic> json,
  ) {
    final route =
        (json['route'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(
              VolunteerDelivery.fromJson,
            )
            .toList();

    final distance = json['totalDistanceKm'];

    return OptimizedVolunteerRoute(
      deliveries: route,
      totalDistanceKm: distance is num
          ? distance.toDouble()
          : double.tryParse(
                distance?.toString() ?? '',
              ) ??
              0,
      googleMapsUrl:
          json['googleMapsUrl']?.toString(),
    );
  }
}

class VolunteerProfileModel {
  final String volunteerId;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String district;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? nic;
  final String availabilityStatus;
  final bool isCompleted;

  const VolunteerProfileModel({
    required this.volunteerId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.district,
    this.vehicleType,
    this.vehicleNumber,
    this.nic,
    this.availabilityStatus = 'AVAILABLE',
    this.isCompleted = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get fullAddress {
    final parts = [addressLine1, addressLine2, city, district]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  factory VolunteerProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map ? json['profile'] as Map<String, dynamic> : json;
    final fName = profile['firstName']?.toString() ?? '';
    final phone = profile['phoneNumber']?.toString() ?? '';
    final addr = profile['addressLine1']?.toString() ?? '';

    return VolunteerProfileModel(
      volunteerId: json['volunteerId']?.toString() ?? profile['volunteerId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: fName,
      lastName: profile['lastName']?.toString() ?? '',
      phoneNumber: phone,
      addressLine1: addr,
      addressLine2: profile['addressLine2']?.toString(),
      city: profile['city']?.toString() ?? '',
      district: profile['district']?.toString() ?? '',
      vehicleType: profile['vehicleType']?.toString(),
      vehicleNumber: profile['vehicleNumber']?.toString(),
      nic: profile['nic']?.toString(),
      availabilityStatus: json['availabilityStatus']?.toString() ?? 'AVAILABLE',
      isCompleted: json['isCompleted'] == true ||
          (fName.isNotEmpty && phone.isNotEmpty && addr.isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'district': district,
    'vehicleType': vehicleType,
    'vehicleNumber': vehicleNumber,
    'nic': nic,
  };
}