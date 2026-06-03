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

    print("LOGIN RESPONSE => $response");

    if (response == null) {
      print("LOGIN FAILED: null response");
      return false;
    }

    final token = response["token"];
    final user = response["user"];

    if (token == null || user == null) {
      print("LOGIN FAILED: missing token/user");
      print("FULL RESPONSE: $response");
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