import 'secrets.dart';

/// Application constants - API endpoint and configuration
class AppConstants {
  // Web Dashboard (Localhost) - Use 10.0.2.2 for Android Emulator, or 192.168.10.103 for physical device
  static const String backendApiEndpoint = 'http://192.168.10.103:3000/api';

  // API Endpoints
  static const String loginApiUrl = Secrets.loginApiUrl;
  static const String tokenApiUrl = Secrets.tokenApiUrl;
  static const String locationApiUrl = Secrets.locationApiUrl;

  // Location update interval in seconds
  static const int updateIntervalSeconds = 10;

  // API timeout settings
  static const int apiTimeoutSeconds = 10;
  static const int maxRetries = 3;

  // SharedPreferences keys
  static const String keyLogin = 'login';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyTrackingEnabled = 'tracking_enabled';
  static const String keySetupComplete = 'setup_complete';

  // Notification settings
  static const String notificationChannelId = 'bus_tracking_channel';
  static const String notificationChannelName = 'Bus Tracking';
  static const int notificationId = 1;
}
