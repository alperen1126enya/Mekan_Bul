import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';

  /// Save user session
  Future<void> saveSession({
    required int userId,
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
  }

  /// Get saved session data
  Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    final username = prefs.getString(_usernameKey);
    final email = prefs.getString(_emailKey);

    if (userId != null && username != null && email != null) {
      return {
        'id': userId,
        'username': username,
        'email': email,
      };
    }
    return null;
  }

  /// Check if session exists
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userIdKey);
  }

  /// Clear session (logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
  }
}
