import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipient_model.dart';

class RecipientService {
  // ================== API BASE URL ==================

  // Android Emulator
  //static const String baseUrl = 'http://10.0.2.2:5001';

  // iOS Simulator / Web
   static const String baseUrl = 'http://localhost:5001';

  // Real Android device
  // static const String baseUrl = 'http://192.168.1.XX:5001';

  // ==================================================

  // ---------- CREATE PROFILE ----------
  static Future<RecipientModel> createProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recipient/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return RecipientModel.fromJson(body['profile']);
    } else {
      if (body['errors'] != null) {
        throw Exception(
          (body['errors'] as List).join(', '),
        );
      }
      throw Exception(body['error'] ?? 'Failed to create profile');
    }
  }

  // ---------- GET PROFILE ----------
  static Future<RecipientModel> getProfile({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recipient/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return RecipientModel.fromJson(body['profile']);
    } else {
      throw Exception(body['error'] ?? 'Failed to fetch profile');
    }
  }

  // ---------- UPDATE PROFILE ----------
  static Future<RecipientModel> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/recipient/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return RecipientModel.fromJson(body['profile']);
    } else {
      if (body['errors'] != null) {
        throw Exception(
          (body['errors'] as List).join(', '),
        );
      }
      throw Exception(body['error'] ?? 'Failed to update profile');
    }
  }

  // ---------- DELETE PROFILE ----------
  static Future<void> deleteProfile({
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/recipient/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete profile');
    }
  }

  // ---------- PROFILE STATUS ----------
  static Future<Map<String, dynamic>> getProfileStatus({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recipient/profile/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Failed to fetch profile status');
    }
  }
}
