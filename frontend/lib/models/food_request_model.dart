class FoodRequestModel {
  final String id;
  final String? customRequestId;
  final String recipientId;
  final String? recipientEmail;
  final String? recipientName;
  final String? recipientContact;
  final String foodItem;
  final String quantityRequested;
  final String? notes;
  final String status;
  final String? rejectionReason;
  final String? deliveryAddress;
  final String? donationId;
  final String? reviewedBy;
  final String? reviewedAt;
  final String? createdAt;
  final String? updatedAt;

  FoodRequestModel({
    required this.id,
    this.customRequestId,
    required this.recipientId,
    this.recipientEmail,
    this.recipientName,
    this.recipientContact,
    required this.foodItem,
    required this.quantityRequested,
    this.notes,
    required this.status,
    this.rejectionReason,
    this.deliveryAddress,
    this.donationId,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodRequestModel.fromJson(Map<String, dynamic> json) {
    return FoodRequestModel(
      id: json['id']?.toString() ?? '',
      customRequestId: json['customRequestId'],
      recipientId: json['recipientId']?.toString() ?? '',
      recipientEmail: json['recipientEmail'],
      recipientName: json['recipientName'],
      recipientContact: json['recipientContact'],
      foodItem: json['foodItem'] ?? '',
      quantityRequested: json['quantityRequested'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'PENDING',
      rejectionReason: json['rejectionReason'],
      deliveryAddress: json['deliveryAddress'],
      donationId: json['donationId'],
      reviewedBy: json['reviewedBy'],
      reviewedAt: json['reviewedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED' || status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';
}
