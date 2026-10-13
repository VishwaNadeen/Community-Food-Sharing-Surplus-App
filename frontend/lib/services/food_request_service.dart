import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_request_model.dart';
import 'auth_service.dart';

class FoodRequestService {

class FoodRequestService {
  static String get baseUrl => AuthService.baseUrl;

  static String get _recipientRequestsUrl =>
      '$baseUrl/api/recipients/requests';

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
  
  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ---------- SUBMIT FOOD REQUEST ----------
  static Future<FoodRequestModel> submitRequest({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse(_recipientRequestsUrl),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201) {
      return FoodRequestModel.fromJson(body['request'] as Map<String, dynamic>);
    }
    if (body['errors'] != null) {
      throw Exception((body['errors'] as List).join(', '));
    }
    throw Exception(body['error'] ?? 'Failed to submit request');
  }

  // ---------- GET MY REQUESTS ----------
  static Future<List<FoodRequestModel>> getMyRequests({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse(_recipientRequestsUrl),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['requests'] as List)
          .map((r) => FoodRequestModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['error'] ?? 'Failed to fetch requests');
  }

  // ---------- GET ALL REQUESTS ----------
  static Future<List<FoodRequestModel>> getAllRequests({
    required String token,
    String? status,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri =
        Uri.parse('$baseUrl/ngo/requests').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers(token));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['requests'] as List)
          .map((r) => FoodRequestModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['error'] ?? 'Failed to fetch requests');
  }

  // ---------- GET PENDING REQUESTS (NGO) ----------
  static Future<List<FoodRequestModel>> getPendingRequests({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/requests/pending'),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['requests'] as List)
          .map((r) => FoodRequestModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['error'] ?? 'Failed to fetch pending requests');
  }

  // ---------- GET REQUEST BY ID ----------
  static Future<FoodRequestModel> getRequestById({
    required String token,
    required String id,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/requests/$id'),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return FoodRequestModel.fromJson(body['request'] as Map<String, dynamic>);
    }
    throw Exception(body['error'] ?? 'Request not found');
  }

  // ---------- APPROVE REQUEST (NGO) ----------
  static Future<FoodRequestModel> approveRequest({
    required String token,
    required String id,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ngo/requests/$id/approve'),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return FoodRequestModel.fromJson(body['request'] as Map<String, dynamic>);
    }
    throw Exception(body['error'] ?? 'Failed to approve request');
  }

  // ---------- REJECT REQUEST (NGO) ----------
  static Future<FoodRequestModel> rejectRequest({
    required String token,
    required String id,
    required String reason,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ngo/requests/$id/reject'),
      headers: _headers(token),
      body: jsonEncode({'rejectionReason': reason}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return FoodRequestModel.fromJson(body['request'] as Map<String, dynamic>);
    }
    if (body['errors'] != null) {
      throw Exception((body['errors'] as List).join(', '));
    }
    throw Exception(body['error'] ?? 'Failed to reject request');
  }

  // ---------- CONFIRM FOOD RECEIVED (Recipient) ----------
  static Future<FoodRequestModel> confirmReceived({
    required String token,
    required String id,
  }) async {
    final response = await http.patch(
      Uri.parse('$_recipientRequestsUrl/$id/confirm-received'),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return FoodRequestModel.fromJson(body['request'] as Map<String, dynamic>);
    }
    throw Exception(body['error'] ?? 'Failed to confirm food received');
  }
}
