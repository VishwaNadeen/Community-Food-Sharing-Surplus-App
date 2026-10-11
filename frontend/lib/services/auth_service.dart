import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // ================== API BASE URL ==================

  // Android Emulator
  //static const String baseUrl = 'http://10.0.2.2:5001';

  // iOS Simulator / Web
  static const String baseUrl = 'http://localhost:5001';

  // Real Android device
  // static const String baseUrl = 'http://192.168.1.XX:5001';

  // ==================================================

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['error'] ?? 'Login failed',
      );
    }
  }

  // ---------- SIGN UP ----------
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
        'role': role,
      }),
    );

    print('SIGNUP STATUS: ${response.statusCode}');
    print('SIGNUP BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      if (data['errors'] != null) {
        throw Exception(
          (data['errors'] as List).join(', '),
        );
      }

      throw Exception(
        data['error'] ?? 'Registration failed',
      );
    }
  }

  // ---------- REGISTER ----------
  // Kept for compatibility with existing code.
  // Calls the same backend /auth/register endpoint.
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    return signup(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
    );
  }

  // ---------- VERIFY EMAIL ----------
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
      }),
    );

    print('VERIFY EMAIL STATUS: ${response.statusCode}');
    print('VERIFY EMAIL BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['error'] ?? 'Verification failed',
      );
    }
  }

  // ---------- RESEND VERIFICATION ----------
  static Future<void> resendVerification(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    print('RESEND STATUS: ${response.statusCode}');
    print('RESEND BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? 'Failed to resend code',
      );
    }
  }

  // ---------- FORGOT PASSWORD ----------
  static Future<void> forgotPassword(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    print('FORGOT PASSWORD STATUS: ${response.statusCode}');
    print('FORGOT PASSWORD BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? 'Failed to send reset code',
      );
    }
  }

  // ---------- RESET PASSWORD ----------
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      }),
    );

    print('RESET PASSWORD STATUS: ${response.statusCode}');
    print('RESET PASSWORD BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? 'Password reset failed',
      );
    }
  }

  // ---------- GET CURRENT USER ----------
  static Future<Map<String, dynamic>> getMe(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('GET ME STATUS: ${response.statusCode}');
    print('GET ME BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['error'] ?? 'Failed to fetch user',
      );
    }
  }
}