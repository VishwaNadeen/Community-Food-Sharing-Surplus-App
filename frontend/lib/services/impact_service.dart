import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/impact_analytics_model.dart';

class ImpactService {
  static const String baseUrl = 'http://10.0.2.2:5001';

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
