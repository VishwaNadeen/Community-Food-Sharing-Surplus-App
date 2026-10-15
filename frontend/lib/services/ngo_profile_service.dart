import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class NgoProfileService {
  static const String baseUrl = 'http://10.0.2.2:5001';

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/profile'),
      headers: _headers(token),
    );
    return _decodeProfile(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/ngo/profile'),
      headers: _headers(token),
      body: jsonEncode({'firstName': firstName, 'lastName': lastName}),
    );
    return _decodeProfile(response);
  }

  static Future<Map<String, dynamic>> uploadPhoto({
    required String token,
    required XFile image,
  }) async {
    final extension = image.path.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      'heif' => MediaType('image', 'heif'),
      _ => MediaType('image', 'jpeg'),
    };
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/ngo/profile/photo'),
    )..headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: mime,
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeProfile(response);
  }

  static Map<String, dynamic> _decodeProfile(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(body['profile'] as Map);
    }
    throw Exception(body['error'] ?? 'Could not save profile');
  }
}
