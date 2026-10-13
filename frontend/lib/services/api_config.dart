
import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const int port = 5001;

  static String get baseUrl {
    // Flutter Web: Chrome and Edge
    if (kIsWeb) {
      return 'http://localhost:$port';
    }

    // Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port';
    }

    // Windows Desktop and iOS Simulator
    return 'http://localhost:$port';
  }
}
