class ImpactAnalyticsModel {
  final DonationStatistics donationStatistics;
  final ImpactSummary summary;
  final List<MonthlyImpact> monthlyImpact;
  final List<CategoryImpact> donationsByCategory;
  final String availabilityNote;

  const ImpactAnalyticsModel({
    required this.donationStatistics,
    required this.summary,
    required this.monthlyImpact,
    required this.donationsByCategory,
    required this.availabilityNote,
  });

  factory ImpactAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['impact'] as Map<String, dynamic>;
    final availability = data['dataAvailability'] as Map<String, dynamic>;
    return ImpactAnalyticsModel(
      donationStatistics: DonationStatistics.fromJson(
        data['donationStatistics'] as Map<String, dynamic>? ?? const {},
      ),
      summary: ImpactSummary.fromJson(data['summary'] as Map<String, dynamic>),
      monthlyImpact: (data['monthlyImpact'] as List<dynamic>)
          .map((item) => MonthlyImpact.fromJson(item as Map<String, dynamic>))
          .toList(),
      donationsByCategory: (data['donationsByCategory'] as List<dynamic>)
          .map((item) => CategoryImpact.fromJson(item as Map<String, dynamic>))
          .toList(),
      availabilityNote: availability['note']?.toString() ?? '',
    );
  }
}

class DonationStatistics {
  final int total;
  final int approved;
  final int completedDeliveryRecords;
  final Map<String, int> byStatus;
  final Map<String, double> quantityByUnit;

  const DonationStatistics({
    required this.total,
    required this.approved,
    required this.completedDeliveryRecords,
    required this.byStatus,
    required this.quantityByUnit,
  });

  factory DonationStatistics.fromJson(Map<String, dynamic> json) =>
      DonationStatistics(
        total: (json['total'] as num?)?.toInt() ?? 0,
        approved: (json['approved'] as num?)?.toInt() ?? 0,
        completedDeliveryRecords:
            (json['completedDeliveryRecords'] as num?)?.toInt() ?? 0,
        byStatus: json['byStatus'] is Map
            ? (json['byStatus'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value as num?)?.toInt() ?? 0,
                ),
              )
            : const {},
        quantityByUnit: ImpactSummary._quantities(json['quantityByUnit']),
      );
}

class VolunteerActivityModel {
  final int totalVolunteers;
  final int availableVolunteers;
  final int totalAssignedDeliveries;
  final int completedDeliveries;
  final int activeDeliveries;
  final Map<String, int> deliveryStatusCounts;
  final List<VolunteerActivity> volunteers;

  const VolunteerActivityModel({
    required this.totalVolunteers,
    required this.availableVolunteers,
    required this.totalAssignedDeliveries,
    required this.completedDeliveries,
    required this.activeDeliveries,
    required this.deliveryStatusCounts,
    required this.volunteers,
  });

  factory VolunteerActivityModel.fromJson(Map<String, dynamic> json) =>
      VolunteerActivityModel(
        totalVolunteers: (json['totalVolunteers'] as num?)?.toInt() ?? 0,
        availableVolunteers: (json['availableVolunteers'] as num?)?.toInt() ?? 0,
        totalAssignedDeliveries:
            (json['totalAssignedDeliveries'] as num?)?.toInt() ?? 0,
        completedDeliveries:
            (json['completedDeliveries'] as num?)?.toInt() ?? 0,
        activeDeliveries: (json['activeDeliveries'] as num?)?.toInt() ?? 0,
        deliveryStatusCounts: json['deliveryStatusCounts'] is Map
            ? (json['deliveryStatusCounts'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value as num?)?.toInt() ?? 0,
                ),
              )
            : const {},
        volunteers: (json['volunteers'] as List<dynamic>? ?? const [])
            .map((item) => VolunteerActivity.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class VolunteerActivity {
  final String volunteerId;
  final int totalDeliveries;
  final int completedDeliveries;
  final int activeDeliveries;
  final DateTime? lastDeliveredAt;

  const VolunteerActivity({
    required this.volunteerId,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.activeDeliveries,
    required this.lastDeliveredAt,
  });

  factory VolunteerActivity.fromJson(Map<String, dynamic> json) =>
      VolunteerActivity(
        volunteerId: json['volunteerId']?.toString() ?? 'Volunteer',
        totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
        completedDeliveries:
            (json['completedDeliveries'] as num?)?.toInt() ?? 0,
        activeDeliveries: (json['activeDeliveries'] as num?)?.toInt() ?? 0,
        lastDeliveredAt: DateTime.tryParse(
          json['lastDeliveredAt']?.toString() ?? '',
        ),
      );
}

class ImpactSummary {
  final int totalDonations;
  final int approvedDonations;
  final int totalRequests;
  final int approvedRequests;
  final int suitableMatches;
  final int acceptedMatches;
  final Map<String, double> donatedQuantityByUnit;
  final Map<String, double> foodWastePreventedByUnit;
  final int? mealsDelivered;
  final int? activeVolunteers;
  final int completedDeliveries;

  const ImpactSummary({
    required this.totalDonations,
    required this.approvedDonations,
    required this.totalRequests,
    required this.approvedRequests,
    required this.suitableMatches,
    required this.acceptedMatches,
    required this.donatedQuantityByUnit,
    required this.foodWastePreventedByUnit,
    this.mealsDelivered,
    this.activeVolunteers,
    required this.completedDeliveries,
  });

  factory ImpactSummary.fromJson(Map<String, dynamic> json) => ImpactSummary(
        totalDonations: (json['totalDonations'] as num?)?.toInt() ?? 0,
        approvedDonations: (json['approvedDonations'] as num?)?.toInt() ?? 0,
        totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
        approvedRequests: (json['approvedRequests'] as num?)?.toInt() ?? 0,
        suitableMatches: (json['suitableMatches'] as num?)?.toInt() ?? 0,
        acceptedMatches: (json['acceptedMatches'] as num?)?.toInt() ?? 0,
        donatedQuantityByUnit: _quantities(json['donatedQuantityByUnit']),
        foodWastePreventedByUnit: _quantities(json['foodWastePreventedByUnit']),
        mealsDelivered: (json['mealsDelivered'] as num?)?.toInt(),
        activeVolunteers: (json['activeVolunteers'] as num?)?.toInt(),
        completedDeliveries: (json['completedDeliveries'] as num?)?.toInt() ?? 0,
      );

  static Map<String, double> _quantities(dynamic source) {
    if (source is! Map) return {};
    return source.map(
      (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
    );
  }
}

class MonthlyImpact {
  final String month;
  final int donations;
  final int requests;
  const MonthlyImpact({required this.month, required this.donations, required this.requests});
  factory MonthlyImpact.fromJson(Map<String, dynamic> json) => MonthlyImpact(
        month: json['month']?.toString() ?? '',
        donations: (json['donations'] as num?)?.toInt() ?? 0,
        requests: (json['requests'] as num?)?.toInt() ?? 0,
      );
}

class CategoryImpact {
  final String category;
  final int count;
  const CategoryImpact({required this.category, required this.count});
  factory CategoryImpact.fromJson(Map<String, dynamic> json) => CategoryImpact(
        category: json['category']?.toString() ?? 'Other',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
