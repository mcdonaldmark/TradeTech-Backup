import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiService {
  static const baseUrl =
      "https://tradetech-api-ksas.onrender.com/api";

  static Uri _url(String endpoint) =>
      Uri.parse("$baseUrl/$endpoint");

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final token = await TokenStorage.getToken();

    final headers = {
      "Content-Type": "application/json",
    };

    if (auth && token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final res = await http.get(
      _url(endpoint),
      headers: await _headers(),
    );

    return _handle(res);
  }

  static Future<dynamic> post(
    String endpoint,
    Map data, {
    bool auth = true,
  }) async {
    final res = await http.post(
      _url(endpoint),
      headers: await _headers(auth: auth),
      body: jsonEncode(data),
    );

    return _handle(res);
  }

  static Future<dynamic> put(String endpoint, Map data) async {
    final res = await http.put(
      _url(endpoint),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return _handle(res);
  }

  static Future<dynamic> delete(String endpoint) async {
    final res = await http.delete(
      _url(endpoint),
      headers: await _headers(),
    );

    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    final body =
        res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw Exception(body?["message"] ?? res.body);
  }
}