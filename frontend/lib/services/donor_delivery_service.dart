import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/donor_delivery_model.dart';

class DonorDeliveryService {
  // Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5001';

  // ---------- GET MY DELIVERIES ----------
  /// Deliveries of the logged-in donor's food that a volunteer accepted.
  static Future<List<DonorDeliveryModel>> getMyDeliveries({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/donors/deliveries'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw Exception(
        'The server returned a non-JSON response '
        '(HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode == 200 && body is Map) {
      final deliveries = body['deliveries'];

      if (deliveries is! List) {
        throw Exception('Unexpected response from server.');
      }

      return deliveries
          .whereType<Map>()
          .map(
            (item) => DonorDeliveryModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    final error = body is Map ? body['error']?.toString() : null;

    throw Exception(
      error ?? 'Failed to load deliveries (HTTP ${response.statusCode}).',
    );
  }
}
