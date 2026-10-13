import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ngo_impact_analytics_model.dart';
import 'api_config.dart';

class ImpactService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<ImpactAnalyticsModel> getImpact({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/impact'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ImpactAnalyticsModel.fromJson(body);
    }
    throw Exception(body['error'] ?? 'Failed to fetch impact analytics');
  }

  static Future<VolunteerActivityModel> getVolunteerActivity({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/impact/volunteers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return VolunteerActivityModel.fromJson(
        body['volunteerActivity'] as Map<String, dynamic>,
      );
    }
    throw Exception(body['error'] ?? 'Failed to fetch volunteer activity');
  }
}
