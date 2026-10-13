class DonationModel {
  final String id;
  final String donorId;
  final String category;
  final double quantity;
  final String quantityUnit;
  final String description;
  final String expiryDate;
  final String? imageUrl;
  final String pickupLocation;
  final String pickupDateTime;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  DonationModel({
    required this.id,
    required this.donorId,
    required this.category,
    required this.quantity,
    required this.quantityUnit,
    required this.description,
    required this.expiryDate,
    this.imageUrl,
    required this.pickupLocation,
    required this.pickupDateTime,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = json['imageUrl'];

    final String? parsedImageUrl =
        rawImageUrl == null || rawImageUrl.toString().trim().isEmpty
            ? null
            : rawImageUrl.toString().trim();

    return DonationModel(
      id: json['id']?.toString() ?? '',
      donorId: json['donorId']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      quantityUnit: json['quantityUnit']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      expiryDate: json['expiryDate']?.toString() ?? '',
      imageUrl: parsedImageUrl,
      pickupLocation: json['pickupLocation']?.toString() ?? '',
      pickupDateTime: json['pickupDateTime']?.toString() ?? '',
      status: json['status']?.toString() ?? 'AVAILABLE',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  // A donation can be claimed only if its status is eligible
  // and both the expiry date and pickup time are still valid.
  bool get isClaimable {
    final normalizedStatus = status.toUpperCase();

    if (normalizedStatus != 'AVAILABLE' &&
        normalizedStatus != 'APPROVED') {
      return false;
    }

    final expiry = DateTime.tryParse(expiryDate);
    final pickup = DateTime.tryParse(pickupDateTime);
    final now = DateTime.now();

    if (expiry == null || pickup == null) {
      return false;
    }

    return expiry.isAfter(now) && !pickup.isBefore(now);
  }

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';

  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  bool get isCollected => status.toUpperCase() == 'COLLECTED';

  bool get isExpired {
    final expiry = DateTime.tryParse(expiryDate);
    return expiry != null && !expiry.isAfter(DateTime.now());
  }
}
