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
    return DonationModel(
      id: json['id']?.toString() ?? '',
      donorId: json['donorId']?.toString() ?? '',
      category: json['category'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      quantityUnit: json['quantityUnit'] ?? '',
      description: json['description'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      imageUrl: json['imageUrl'],
      pickupLocation: json['pickupLocation'] ?? '',
      pickupDateTime: json['pickupDateTime'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  bool get isAvailable => status == 'AVAILABLE';
  bool get isCancelled => status == 'CANCELLED';
  bool get isCollected => status == 'COLLECTED';
  bool get isExpired => status == 'EXPIRED';
}
