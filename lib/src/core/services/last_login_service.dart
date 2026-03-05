import 'package:shared_preferences/shared_preferences.dart';

abstract class LastLoginService {
  static const _keyIdentifier = 'last_login_identifier';
  static const _keyClearedAt = 'password_cleared_at';

  static Future<void> saveLastLoginIdentifier(String emailOrUsername) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIdentifier, emailOrUsername.trim());
  }

  static Future<String?> getLastLoginIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIdentifier);
  }

  static Future<void> markPasswordCleared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyClearedAt, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> shouldClearPassword({int inactiveMinutes = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final clearedAt = prefs.getInt(_keyClearedAt);
    if (clearedAt == null) return false;
    final diff = DateTime.now().millisecondsSinceEpoch - clearedAt;
    return diff >= inactiveMinutes * 60 * 1000;
  }
}
