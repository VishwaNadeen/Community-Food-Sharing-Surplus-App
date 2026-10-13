
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _profileCompleted = false;
  bool _isLoading = false;

  // ================== GETTERS ==================

  UserModel? get user => _user;

  String? get token => _token;

  bool get profileCompleted => _profileCompleted;

  bool get isLoggedIn => _token != null && _user != null;

  bool get isLoading => _isLoading;

  String? get roleCode => _user?.roleCode;

  static const String _tokenKey = 'auth_token';

  // ================== RESTORE SESSION ==================

  
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken == null) {
      _token = null;
      _user = null;
      _profileCompleted = false;
      notifyListeners();
      return;
    }

    try {
      final data = await AuthService.getMe(savedToken);
      final userData = Map<String, dynamic>.from(
        data['user'] as Map,
      );

      _token = savedToken;
      _user = UserModel.fromJson({
        'isEmailVerified': true,
        ...userData,
      });

      _profileCompleted =
          data['profileCompleted'] as bool? ?? false;
    } catch (error) {
      debugPrint('Session restoration failed: $error');

      await prefs.remove(_tokenKey);
      _token = null;
      _user = null;
      _profileCompleted = false;
    }

    notifyListeners();
  }
  // ================== LOGIN ==================

  
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

        final token = result['token'] as String;
        final userData = Map<String, dynamic>.from(
          result['user'] as Map,
        );

        final user = UserModel.fromJson({
          'isEmailVerified': true,
          ...userData,
        });

        final profileCompleted =
            result['profileCompleted'] as bool? ?? false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        _token = token;
        _user = user;
        _profileCompleted = profileCompleted;
      } catch (_) {
        _token = null;
        _user = null;
        _profileCompleted = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);

        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }

  // ================== LOGOUT ==================

  Future<void> logout() async {
    _token = null;
    _user = null;
    _profileCompleted = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    notifyListeners();
  }

  // ================== UPDATE PROFILE STATUS ==================

  void setProfileCompleted(bool value) {
    _profileCompleted = value;
    notifyListeners();
  }

  // ================== REFRESH DONOR PROFILE STATUS ==================

  Future<void> refreshDonorProfileStatus() async {
    final currentToken = _token;

    if (currentToken == null || roleCode != 'D') {
      return;
    }

    try {
      final result =
          await AuthService.getDonorProfileStatus(currentToken);

      setProfileCompleted(
        result['profileCompleted'] as bool? ?? false,
      );
    } catch (error) {
      debugPrint(
        'Failed to refresh donor profile status: $error',
      );

      rethrow;
    }
  }
}
