import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';

class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Error ${res.statusCode}');
    }
    return data;
  }
}
