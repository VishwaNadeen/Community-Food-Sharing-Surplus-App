class ImpactAnalyticsModel {
  final ImpactSummary summary;
  final List<MonthlyImpact> monthlyImpact;
  final List<CategoryImpact> donationsByCategory;
  final String availabilityNote;

  const ImpactAnalyticsModel({
    required this.summary,
    required this.monthlyImpact,
    required this.donationsByCategory,
    required this.availabilityNote,
  });

  factory ImpactAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['impact'] as Map<String, dynamic>;
    final availability = data['dataAvailability'] as Map<String, dynamic>;
    return ImpactAnalyticsModel(
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
