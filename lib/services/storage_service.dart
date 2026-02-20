import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Service for persistent storage using SharedPreferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Driver Information
  Future<void> saveAuthTokens(
    String login,
    String accessToken,
    String refreshToken,
  ) async {
    await prefs.setString(AppConstants.keyLogin, login);
    await prefs.setString(AppConstants.keyAccessToken, accessToken);
    await prefs.setString(AppConstants.keyRefreshToken, refreshToken);
    await prefs.setBool(AppConstants.keySetupComplete, true);
  }

  String? getLogin() {
    return prefs.getString(AppConstants.keyLogin);
  }

  String? getAccessToken() {
    return prefs.getString(AppConstants.keyAccessToken);
  }

  String? getRefreshToken() {
    return prefs.getString(AppConstants.keyRefreshToken);
  }

  bool isSetupComplete() {
    return prefs.getBool(AppConstants.keySetupComplete) ?? false;
  }

  // Tracking State
  Future<void> setTrackingEnabled(bool enabled) async {
    await prefs.setBool(AppConstants.keyTrackingEnabled, enabled);
  }

  bool getTrackingEnabled() {
    return prefs.getBool(AppConstants.keyTrackingEnabled) ?? false;
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    await prefs.clear();
  }
}
