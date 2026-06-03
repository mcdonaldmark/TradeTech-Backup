import '../api/api_service.dart';
import '../../storage/token_storage.dart';

class AuthService {
  static String? _token;
  static String? currentRole;
  static int? currentUserId;
  static String? currentUserName;

  static Future<bool> login(String email, String password) async {
    try {
      final res = await ApiService.post(
        "auth/login",
        {
          "email": email,
          "password": password,
        },
        auth: false,
      );

      final data = res["data"] ?? res;

      final token = data["token"];
      final user = data["user"];

      if (token == null || user == null) return false;

      _token = token;
      await TokenStorage.saveToken(token);

      currentRole = user["role"];
      currentUserId = user["id"];
      currentUserName = user["name"];

      return true;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return false;
    }
  }

  static Future<void> loadSession() async {
    _token = await TokenStorage.getToken();
  }

  static Future<void> logout() async {
    _token = null;
    currentRole = null;
    currentUserId = null;
    currentUserName = null;
    await TokenStorage.clear();
  }
}