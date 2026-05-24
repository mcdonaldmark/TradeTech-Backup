import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiService {
  static const String baseUrl = "http://192.168.68.114:5000/api";

  static Future<Map<String, String>> _headers({
    bool includeAuth = true,
  }) async {
    final token = await TokenStorage.getToken();

    return {
      "Content-Type": "application/json",
      if (includeAuth && token != null)
        "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final res = await http
          .get(
            Uri.parse("$baseUrl/$endpoint"),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10)); // 🔥 FIX

      return _handleResponse(res);
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  static Future<dynamic> post(
    String endpoint,
    Map data, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/$endpoint"),
            headers: await _headers(includeAuth: auth),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10)); // 🔥 FIX

      return _handleResponse(res);
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  static Future<dynamic> put(String endpoint, Map data) async {
    try {
      final res = await http
          .put(
            Uri.parse("$baseUrl/$endpoint"),
            headers: await _headers(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(res);
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      final res = await http
          .delete(
            Uri.parse("$baseUrl/$endpoint"),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(res);
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  static dynamic _handleResponse(http.Response res) {
    final decoded =
        res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw Exception(
      decoded?["message"] ?? decoded?["error"] ?? res.body,
    );
  }
}