import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000/api"; 
  // Android emulator uses 10.0.2.2 instead of localhost

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final res = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<dynamic> post(String endpoint, Map data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<dynamic> put(String endpoint, Map data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<dynamic> delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }
}