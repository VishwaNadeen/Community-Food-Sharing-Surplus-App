import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ngo_food_match_model.dart';
import 'api_config.dart';

class MatchingService {
  // Android Emulator
  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };

  static Future<List<FoodMatchModel>> generateMatches({
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ngo/matches/generate'),
      headers: _headers(token),
    );
    return _parseMatches(response, 'Failed to generate food matches');
  }

  static Future<List<FoodMatchModel>> getMatches({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ngo/matches'),
      headers: _headers(token),
    );
    return _parseMatches(response, 'Failed to fetch food matches');
  }

  static List<FoodMatchModel> _parseMatches(
    http.Response response,
    String fallbackError,
  ) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return (body['matches'] as List)
          .map(
            (match) => FoodMatchModel.fromJson(match as Map<String, dynamic>),
          )
          .toList();
    }
    throw Exception(body['error'] ?? fallbackError);
  }
}
