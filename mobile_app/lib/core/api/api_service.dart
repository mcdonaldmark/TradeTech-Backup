import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiService {
  static const String baseUrl =
      "https://tradetech-api-ksas.onrender.com/api";

  static Uri _url(String endpoint) {
    return Uri.parse("$baseUrl/$endpoint");
  }

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

  static Future<dynamic> post(
    String endpoint,
    Map data, {
    bool auth = true,
  }) async {
    final url = _url(endpoint);

    print("📡 POST => $url");
    print("📦 BODY => $data");

    final res = await http.post(
      url,
      headers: await _headers(includeAuth: auth),
      body: jsonEncode(data),
    );

    print("📥 STATUS => ${res.statusCode}");
    print("📥 RESPONSE => ${res.body}");

    return _handleResponse(res);
  }

  static dynamic _handleResponse(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw Exception(decoded?["message"] ?? decoded?["error"] ?? res.body);
  }
}