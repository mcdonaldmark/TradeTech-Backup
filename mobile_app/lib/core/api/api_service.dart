import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiService {
  static const String baseUrl = "http://192.168.68.114:5000/api";

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static dynamic _handle(http.Response res) {
    final body = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw Exception(body["message"] ?? body["error"] ?? "Request failed");
  }

  static Future get(String endpoint) async {
    final res = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );
    return _handle(res);
  }

  static Future post(String endpoint, Map data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  static Future put(String endpoint, Map data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  static Future delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );
    return _handle(res);
  }
}