class FoodMatchModel {
  final String id;
  final String status;
  final int score;
  final bool categoryMatched;
  final bool locationMatched;
  final Map<String, dynamic> donation;
  final Map<String, dynamic> foodRequest;

  FoodMatchModel({
    required this.id,
    required this.status,
    required this.score,
    required this.categoryMatched,
    required this.locationMatched,
    required this.donation,
    required this.foodRequest,
  });

  factory FoodMatchModel.fromJson(Map<String, dynamic> json) {
    return FoodMatchModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SUGGESTED',
      score: (json['score'] as num?)?.toInt() ?? 0,
      categoryMatched: json['categoryMatched'] == true,
      locationMatched: json['locationMatched'] == true,
      donation: Map<String, dynamic>.from(json['donation'] ?? const {}),
      foodRequest: Map<String, dynamic>.from(json['foodRequest'] ?? const {}),
    );
  }
}
