import '../storage/token_storage.dart';
import '../api/api_service.dart';

class AuthService {
  static String? _token;
  static String? currentRole;
  static int? currentUserId;
  static String? currentUserName;

  static String? get token => _token;

  // LOAD SESSION
  static Future<void> loadSession() async {
    _token = await TokenStorage.getToken();
  }

  // LOGIN
  static Future<bool> login(String email, String password) async {
  try {
    final response = await ApiService.post(
      "auth/login",
      {
        "email": email,
        "password": password,
      },
      auth: false,
    );

    print("LOGIN RAW RESPONSE: $response");

    final data = response["data"] ?? response;

    final token = data["token"] ?? response["token"];
    final user = data["user"] ?? response["user"];

    if (token == null || user == null) {
      print("LOGIN FAILED: missing token/user");
      print("TOKEN: $token");
      print("USER: $user");
      return false;
    }

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

  // LOGOUT
  static Future<void> logout() async {
    _token = null;
    currentRole = null;
    currentUserId = null;
    currentUserName = null;
    await TokenStorage.clear();
  }
}