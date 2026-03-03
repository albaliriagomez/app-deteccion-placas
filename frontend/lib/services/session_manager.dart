class SessionManager {
  static String? semToken;
  static String? username;
  static String? role;

  static bool get isLoggedIn => semToken != null;

  static void clearSession() {
    semToken = null;
    username = null;
    role = null;
  }
}