import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _profileCompleted = false;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get profileCompleted => _profileCompleted;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String? get roleCode => _user?.roleCode;

  static const _tokenKey = 'auth_token';

  // -------------------- load on app start --------------------

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken != null) {
      try {
        final data = await AuthService.getMe(savedToken);
        final userData = data['user'];
        _token = savedToken;
        // /auth/me omits isEmailVerified; a token only exists after a verified login.
        _user = UserModel.fromJson({
          'isEmailVerified': true,
          ...(userData as Map<String, dynamic>),
        });
        _profileCompleted = data['profileCompleted'] ?? true;
      } catch (_) {
        await prefs.remove(_tokenKey);
        _token = null;
        _user = null;
      }
    }
    notifyListeners();
  }

  // -------------------- login --------------------

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );
      _token = result['token'] as String;
      // Login only succeeds for verified emails, and the response omits the flag.
      _user = UserModel.fromJson({
        'isEmailVerified': true,
        ...(result['user'] as Map<String, dynamic>),
      });
      _profileCompleted = result['profileCompleted'] as bool? ?? true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------- logout --------------------

  Future<void> logout() async {
    _token = null;
    _user = null;
    _profileCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  // -------------------- helpers --------------------

  void setProfileCompleted(bool value) {
    _profileCompleted = value;
    notifyListeners();
  }
}
