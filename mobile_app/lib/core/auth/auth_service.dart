import '../api/api_service.dart';
import '../storage/token_storage.dart';

class AuthService {
  static String? currentRole;
  static int? currentUserId;

  static Future<bool> login(String email, String password) async {
    final response = await ApiService.post("auth/login", {
      "email": email,
      "password": password
    });

    if (response == null) return false;

    if (response["token"] != null) {
      await TokenStorage.saveToken(response["token"]);

      currentRole = response["user"]["role"];
      currentUserId = response["user"]["id"];

      return true;
    }

    return false;
  }

  static void logout() {
    currentRole = null;
    currentUserId = null;
    TokenStorage.clear();
  }
}