import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ngo_admin_model.dart';
import 'api_config.dart';

class NgoAdminService {
  static String get baseUrl => ApiConfig.baseUrl;
  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  static Future<Map<String, dynamic>> _get(String path, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/admin/$path'),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Request failed (${response.statusCode})');
  }

  static Future<AdminOverview> getOverview({required String token}) async {
    final body = await _get('overview', token);
    return AdminOverview.fromJson(body['overview'] as Map<String, dynamic>);
  }

  static Future<List<AdminDonor>> getDonors({required String token}) async {
    final body = await _get('donors', token);
    return (body['donors'] as List<dynamic>)
        .map((e) => AdminDonor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AdminRecipient>> getRecipients({
    required String token,
  }) async {
    final body = await _get('recipients', token);
    return (body['recipients'] as List<dynamic>)
        .map((e) => AdminRecipient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AdminAlert>> getAlerts({required String token}) async {
    final body = await _get('alerts', token);
    return (body['alerts'] as List<dynamic>)
        .map((e) => AdminAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateAlertStatus({
    required String token,
    required String id,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ngo/admin/alerts/$id/status'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['error'] ?? 'Failed to update alert');
  }
}
