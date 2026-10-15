import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the welcome slides have been shown on this device.
///
/// Kept separate from the login session (AuthProvider), so logging out
/// does not show the slides again. Only a true/false flag is stored here,
/// never any account data.
class OnboardingService {
  static const String _seenKey = 'has_seen_onboarding';

  /// True once the user has finished or skipped the welcome slides.
  static Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      // If storage cannot be read, do not block the user with slides.
      return true;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {
      // Not critical: at worst the slides show once more next launch.
    }
  }
}
