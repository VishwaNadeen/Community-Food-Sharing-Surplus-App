import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/donation_model.dart';

class DonationService {
  // Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5001';

  // iOS Simulator / Web
  //static const String baseUrl = 'http://localhost:5001';

  static Map<String, String> _authHeader(String token) => {
    'Authorization': 'Bearer $token',
  };

  // ---------- CREATE DONATION ----------
  static Future<DonationModel> createDonation({
    required String token,
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/donations'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    fields.forEach((key, value) => request.fields[key] = value);
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201) {
      return DonationModel.fromJson(body['donation'] as Map<String, dynamic>);
    }
    if (body['errors'] != null) {
      throw Exception((body['errors'] as List).join(', '));
    }
    throw Exception(body['error'] ?? 'Failed to create donation');
  }

  // ---------- GET MY DONATIONS ----------
  static Future<List<DonationModel>> getMyDonations({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/donations'),
      headers: _authHeader(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['donations'] as List)
          .map((d) => DonationModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['error'] ?? 'Failed to fetch donations');
  }

  // ---------- CANCEL DONATION ----------
  static Future<DonationModel> cancelDonation({
    required String token,
    required String id,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/donations/$id/cancel'),
      headers: _authHeader(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return DonationModel.fromJson(body['donation'] as Map<String, dynamic>);
    }
    throw Exception(body['error'] ?? 'Failed to cancel donation');
  }

  // ---------- NGO COORDINATOR REVIEW ----------
  static Future<List<DonationModel>> getPendingDonations({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/donations/pending'),
      headers: _authHeader(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['donations'] as List)
          .map((d) => DonationModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['error'] ?? 'Failed to fetch pending donations');
  }

  static Future<List<DonationModel>> getAllDonations({
    required String token,
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/ngo/donations').replace(
      queryParameters: status == null || status == 'All'
          ? null
          : {'status': status},
    );
    final response = await http.get(uri, headers: _authHeader(token));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['donations'] as List)
          .map((d) => DonationModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['error'] ?? 'Failed to fetch donations');
  }

  static Future<DonationModel> approveDonation({
    required String token,
    required String id,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ngo/donations/$id/approve'),
      headers: _authHeader(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return DonationModel.fromJson(body['donation'] as Map<String, dynamic>);
    }
    throw Exception(body['error'] ?? 'Failed to approve donation');
  }

  static Future<DonationModel> rejectDonation({
    required String token,
    required String id,
    required String reason,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ngo/donations/$id/reject'),
      headers: {..._authHeader(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'rejectionReason': reason}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return DonationModel.fromJson(body['donation'] as Map<String, dynamic>);
    }
    if (body['errors'] != null) {
      throw Exception((body['errors'] as List).join(', '));
    }
    throw Exception(body['error'] ?? 'Failed to reject donation');
  }

  // ---------- BROWSE DONATIONS (Recipient) ----------
  static Future<List<DonationModel>> browseDonations({
    required String token,
    String? category,
    String? location,
    String availability = 'available',
  }) async {
    final params = <String, String>{'availability': availability};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (location != null && location.isNotEmpty) params['location'] = location;

    final uri = Uri.parse(
      '$baseUrl/api/recipients/donations',
    ).replace(queryParameters: params);

    final response = await http.get(uri, headers: _authHeader(token));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['donations'] as List)
          .map((d) => DonationModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['error'] ?? 'Failed to browse donations');
  }

  // ---------- GET DONATION DETAIL (Recipient) ----------
  static Future<DonationModel> getDonationDetail({
    required String token,
    required String id,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/recipients/donations/$id'),
      headers: _authHeader(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return DonationModel.fromJson(body['donation'] as Map<String, dynamic>);
    }
    throw Exception(body['error'] ?? 'Donation not found');
  }
}
