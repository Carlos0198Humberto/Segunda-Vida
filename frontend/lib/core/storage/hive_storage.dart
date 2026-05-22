import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class HiveStorage {
  static late Box _authBox;
  static late Box _settingsBox;
  static late Box _cacheBox;

  static Future<void> init() async {
    _authBox = await Hive.openBox(AppConstants.authBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _cacheBox = await Hive.openBox(AppConstants.cacheBox);
  }

  // Auth
  static Future<void> saveToken(String token) =>
      _authBox.put(AppConstants.tokenKey, token);

  static String? getToken() => _authBox.get(AppConstants.tokenKey);

  static Future<void> saveRefreshToken(String token) =>
      _authBox.put(AppConstants.refreshTokenKey, token);

  static String? getRefreshToken() => _authBox.get(AppConstants.refreshTokenKey);

  static Future<void> clearAuth() async {
    await _authBox.delete(AppConstants.tokenKey);
    await _authBox.delete(AppConstants.refreshTokenKey);
    await _authBox.delete(AppConstants.userKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _authBox.put(AppConstants.userKey, user);

  static Map<String, dynamic>? getUser() {
    final data = _authBox.get(AppConstants.userKey);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static bool get isLoggedIn => getToken() != null;

  // Settings
  static Future<void> putString(String key, String value) =>
      _settingsBox.put(key, value);

  static String? getString(String key) => _settingsBox.get(key);

  static Future<void> putBool(String key, bool value) =>
      _settingsBox.put(key, value);

  static bool getBool(String key, {bool defaultValue = false}) =>
      _settingsBox.get(key, defaultValue: defaultValue) as bool;

  static Future<void> putInt(String key, int value) =>
      _settingsBox.put(key, value);

  static int getInt(String key, {int defaultValue = 0}) =>
      (_settingsBox.get(key, defaultValue: defaultValue) as num).toInt();

  // Locale
  static Future<void> saveLocale(String locale) =>
      _settingsBox.put('locale', locale);

  static String getLocale() => _settingsBox.get('locale', defaultValue: 'es') as String;

  // Cache
  static Future<void> putCache(String key, dynamic value) =>
      _cacheBox.put(key, value);

  static dynamic getCache(String key) => _cacheBox.get(key);

  static Future<void> clearCache() => _cacheBox.clear();
}
