import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/donation_model.dart';
import 'api_config.dart';

class DonationService {
  // Android Emulator
  // Automatically selects backend URL for each platform.
  static String get baseUrl => ApiConfig.baseUrl;

  // Use localhost for Flutter Web or environments where localhost
  // points to the machine running the backend.
  // static const String webBaseUrl = 'http://localhost:5001';
  // iOS Simulator / Web
  //static const String baseUrl = 'http://localhost:5001';

  static Map<String, String> _authHeader(String token) => {
    'Authorization': 'Bearer $token',
  };

  // Determine the MIME type from the selected image's extension.
  static MediaType? _getImageContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return null;
    }
  }

  // Create a multipart image file with the correct MIME type.
  static Future<http.MultipartFile> _createImagePart(
    File imageFile,
  ) async {
    final contentType = _getImageContentType(imageFile.path);

    if (contentType == null) {
      throw Exception(
        'Unsupported image format. Please select a JPEG, PNG, or WebP image.',
      );
    }

    return http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: contentType,
    );
  }

  // Safely decode API responses.
  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    final responseBody = response.body.trim();

    if (responseBody.isEmpty) {
      return {
        'error': 'The server returned an empty response '
            '(HTTP ${response.statusCode}).',
      };
    }

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'error': 'Unexpected response format from server.',
      };
    } on FormatException {
      return {
        'error': 'The server returned a non-JSON response '
            '(HTTP ${response.statusCode}). '
            'Check the backend URL, API route, and server logs.',
      };
    }
  }

  static String _errorMessage(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final errors = body['errors'];

    if (errors is List) {
      return errors.join(', ');
    }

    final error = body['error'];

    if (error is String && error.isNotEmpty) {
      return error;
    }

    final message = body['message'];

    if (message is String && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

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
    request.fields.addAll(fields);

    if (imageFile != null) {
      request.files.add(await _createImagePart(imageFile));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeResponse(response);

    if (response.statusCode == 201) {
      final donation = body['donation'];

      if (donation is Map<String, dynamic>) {
        return DonationModel.fromJson(donation);
      }

      throw Exception(
        'Donation was created, but the response did not contain '
        'valid donation data.',
      );
    }

    throw Exception(
      _errorMessage(body, 'Failed to create donation.'),
    );
  }

  // ---------- GET MY DONATIONS ----------
  static Future<List<DonationModel>> getMyDonations({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/donations'),
      headers: _authHeader(token),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      final donations = body['donations'];

      if (donations is! List) {
        throw Exception('Invalid donations response from server.');
      }

      return donations
          .map(
            (donation) => DonationModel.fromJson(
              donation as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _errorMessage(body, 'Failed to fetch donations.'),
    );
  }

  // ---------- UPDATE DONATION ----------
  static Future<DonationModel> updateDonation({
    required String token,
    required String id,
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/donations/$id'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);

    if (imageFile != null) {
      request.files.add(await _createImagePart(imageFile));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      final donation = body['donation'];

      if (donation is Map<String, dynamic>) {
        return DonationModel.fromJson(donation);
      }

      throw Exception(
        'Donation was updated, but the response did not contain '
        'valid donation data.',
      );
    }

    throw Exception(
      _errorMessage(body, 'Failed to update donation.'),
    );
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

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      final donation = body['donation'];

      if (donation is Map<String, dynamic>) {
        return DonationModel.fromJson(donation);
      }

      throw Exception(
        'Donation was cancelled, but the response did not contain '
        'valid donation data.',
      );
    }

    throw Exception(
      _errorMessage(body, 'Failed to cancel donation.'),
    );
  }


  // ---------- NGO COORDINATOR REVIEW ----------

  static Future<List<DonationModel>> getPendingDonations({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/donations/pending'),
      headers: _authHeader(token),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      final donations = body['donations'];

      if (donations is! List) {
        throw Exception('Invalid pending donations response.');
      }

      return donations
          .map(
            (d) => DonationModel.fromJson(
              d as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _errorMessage(body, 'Failed to fetch pending donations.'),
    );
  }

  static Future<List<DonationModel>> getAllDonations({
    required String token,
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/ngo/donations').replace(
      queryParameters:
          status == null || status == 'All' ? null : {'status': status},
    );

    final response = await http.get(
      uri,
      headers: _authHeader(token),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      final donations = body['donations'];

      if (donations is! List) {
        throw Exception('Invalid donations response.');
      }

      return donations
          .map(
            (d) => DonationModel.fromJson(
              d as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _errorMessage(body, 'Failed to fetch donations.'),
    );
  }

  static Future<DonationModel> approveDonation({
    required String token,
    required String id,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ngo/donations/$id/approve'),
      headers: _authHeader(token),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 &&
        body['donation'] is Map<String, dynamic>) {
      return DonationModel.fromJson(
        body['donation'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      _errorMessage(body, 'Failed to approve donation.'),
    );
  }

  static Future<DonationModel> rejectDonation({
    required String token,
    required String id,
    required String reason,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ngo/donations/$id/reject'),
      headers: {
        ..._authHeader(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rejectionReason': reason}),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 &&
        body['donation'] is Map<String, dynamic>) {
      return DonationModel.fromJson(
        body['donation'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      _errorMessage(body, 'Failed to reject donation.'),
    );
  }
  
  // ---------- BROWSE DONATIONS (RECIPIENT) ----------
  static Future<List<DonationModel>> browseDonations({
    required String token,
    String? category,
    String? location,
    String availability = 'available',
  }) async {
    final params = <String, String>{
      'availability': availability,
    };

    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }

    if (location != null && location.isNotEmpty) {
      params['location'] = location;
    }

    final uri = Uri.parse(
      '$baseUrl/api/recipients/donations',
    ).replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: _authHeader(token),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      final donations = body['donations'];

      if (donations is! List) {
        throw Exception('Invalid donations response from server.');
      }

      return donations
          .map(
            (donation) => DonationModel.fromJson(
              donation as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _errorMessage(body, 'Failed to browse donations.'),
    );
  }

  // ---------- GET DONATION DETAIL (RECIPIENT) ----------
  static Future<DonationModel> getDonationDetail({
    required String token,
    required String id,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/recipients/donations/$id'),
      headers: _authHeader(token),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      final donation = body['donation'];

      if (donation is Map<String, dynamic>) {
        return DonationModel.fromJson(donation);
      }

      throw Exception('Invalid donation details response from server.');
    }

    throw Exception(
      _errorMessage(body, 'Donation not found.'),
    );
  }
}
