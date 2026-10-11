int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

class AdminTask {
  final String type;
  final String title;
  final String detail;
  final String priority;
  final String createdAt;

  const AdminTask({
    required this.type,
    required this.title,
    required this.detail,
    required this.priority,
    required this.createdAt,
  });

  factory AdminTask.fromJson(Map<String, dynamic> json) => AdminTask(
        type: json['type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'MEDIUM',
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class AdminOverview {
  final int donors;
  final int recipients;
  final int volunteers;
  final int donationsThisMonth;
  final int pendingDonations;
  final int pendingRequests;
  final int pendingDeliveries;
  final int openProblems;
  final List<AdminTask> priorityTasks;

  const AdminOverview({
    required this.donors,
    required this.recipients,
    required this.volunteers,
    required this.donationsThisMonth,
    required this.pendingDonations,
    required this.pendingRequests,
    required this.pendingDeliveries,
    required this.openProblems,
    required this.priorityTasks,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>? ?? const {};
    return AdminOverview(
      donors: _int(metrics['donors']),
      recipients: _int(metrics['recipients']),
      volunteers: _int(metrics['volunteers']),
      donationsThisMonth: _int(metrics['donationsThisMonth']),
      pendingDonations: _int(metrics['pendingDonations']),
      pendingRequests: _int(metrics['pendingRequests']),
      pendingDeliveries: _int(metrics['pendingDeliveries']),
      openProblems: _int(metrics['openProblems']),
      priorityTasks: (json['priorityTasks'] as List<dynamic>? ?? const [])
          .map((e) => AdminTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminDonor {
  final String customUserId;
  final String email;
  final String joinedAt;
  final int totalDonations;
  final int approvedDonations;
  final int pendingDonations;
  final int rejectedDonations;
  final String? lastDonationAt;
  final String status;

  const AdminDonor({
    required this.customUserId,
    required this.email,
    required this.joinedAt,
    required this.totalDonations,
    required this.approvedDonations,
    required this.pendingDonations,
    required this.rejectedDonations,
    required this.lastDonationAt,
    required this.status,
  });

  factory AdminDonor.fromJson(Map<String, dynamic> json) => AdminDonor(
        customUserId: json['customUserId']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        joinedAt: json['joinedAt']?.toString() ?? '',
        totalDonations: _int(json['totalDonations']),
        approvedDonations: _int(json['approvedDonations']),
        pendingDonations: _int(json['pendingDonations']),
        rejectedDonations: _int(json['rejectedDonations']),
        lastDonationAt: json['lastDonationAt']?.toString(),
        status: json['status']?.toString() ?? 'NEW',
      );
}

class AdminRecipient {
  final String customUserId;
  final String name;
  final String email;
  final String phoneNumber;
  final String location;
  final int totalRequests;
  final int approvedRequests;
  final int pendingRequests;
  final int rejectedRequests;
  final String? lastRequestAt;
  final String status;

  const AdminRecipient({
    required this.customUserId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.totalRequests,
    required this.approvedRequests,
    required this.pendingRequests,
    required this.rejectedRequests,
    required this.lastRequestAt,
    required this.status,
  });

  factory AdminRecipient.fromJson(Map<String, dynamic> json) => AdminRecipient(
        customUserId: json['customUserId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        totalRequests: _int(json['totalRequests']),
        approvedRequests: _int(json['approvedRequests']),
        pendingRequests: _int(json['pendingRequests']),
        rejectedRequests: _int(json['rejectedRequests']),
        lastRequestAt: json['lastRequestAt']?.toString(),
        status: json['status']?.toString() ?? 'NEW',
      );
}

class AdminAlert {
  final String id;
  final String volunteerId;
  final String problemType;
  final String description;
  final String status;
  final String foodItem;
  final String deliveryStatus;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String createdAt;

  const AdminAlert({
    required this.id,
    required this.volunteerId,
    required this.problemType,
    required this.description,
    required this.status,
    required this.foodItem,
    required this.deliveryStatus,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.createdAt,
  });

  factory AdminAlert.fromJson(Map<String, dynamic> json) => AdminAlert(
        id: json['id']?.toString() ?? '',
        volunteerId: json['volunteerId']?.toString() ?? '',
        problemType: json['problemType']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status: json['status']?.toString() ?? 'REPORTED',
        foodItem: json['foodItem']?.toString() ?? '',
        deliveryStatus: json['deliveryStatus']?.toString() ?? '',
        pickupAddress: json['pickupAddress']?.toString(),
        dropoffAddress: json['dropoffAddress']?.toString(),
        createdAt: json['createdAt']?.toString() ?? '',
      );

  bool get isResolved => status == 'RESOLVED';
}
