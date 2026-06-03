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

    final data = (response is Map && response["token"] != null)
        ? response
        : response?["data"] ?? response;

    final token = data?["token"];
    final user = data?["user"];

    if (token == null || user == null) return false;

    _token = token;
    await TokenStorage.saveToken(token);

    currentRole = user["role"];
    currentUserId = user["id"];
    currentUserName = user["name"];

    return true;
  } catch (e) {
    return false;
  }
}