import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// En web desde el celular usa la misma IP del servidor + puerto 3000.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:3000';
      }
    }
    return 'http://localhost:3000';
  }
}
