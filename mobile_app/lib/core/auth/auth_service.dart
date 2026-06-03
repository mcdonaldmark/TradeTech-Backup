import '../storage/token_storage.dart';

class AuthService {
  static String? _token;

  static String? currentRole;
  static int? currentUserId;
  static String? currentUserName;

  // ================= LOGIN =================
  static Future<void> loginUser(
    String token,
    Map<String, dynamic> user,
  ) async {
    _token = token;

    currentRole = user["role"];
    currentUserId = user["id"];
    currentUserName = user["name"];

    await TokenStorage.saveToken(token);
  }

  // ================= LOAD TOKEN =================
  static Future<void> loadToken() async {
    _token = await TokenStorage.getToken();
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    _token = null;
    currentRole = null;
    currentUserId = null;
    currentUserName = null;

    await TokenStorage.clear();
  }

  static String? get token => _token;
}