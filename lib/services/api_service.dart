import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_data.dart';
import '../constants.dart';
import 'storage_service.dart';

/// Service for sending location data to the backend API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Authenticate driver and get the token
  Future<bool> login(String login, String password) async {
    try {
      final jsonBody = jsonEncode({'username': login, 'password': password});

      final response = await http
          .post(
            Uri.parse(AppConstants.tokenApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonBody,
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String accessToken = '';
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            accessToken =
                data['token'] ??
                data['access'] ??
                data['key'] ??
                data['access_token'] ??
                '';
          }
        } catch (_) {
          if (response.body.isNotEmpty && !response.body.startsWith('{')) {
            accessToken = response.body.trim();
          }
        }

        if (accessToken.isNotEmpty) {
          final storage = StorageService();
          await storage.saveAuthTokens(login, accessToken, '');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error logging in: $e');
      return false;
    }
  }

  /// Send location data to the server
  /// Returns true if successful, false otherwise
  Future<bool> sendLocation(LocationData data) async {
    final storage = StorageService();
    final accessToken = storage.getAccessToken() ?? '';

    for (int attempt = 1; attempt <= AppConstants.maxRetries; attempt++) {
      try {
        print(
          'Sending location (attempt $attempt/${AppConstants.maxRetries}): ${data.toString()}',
        );

        final response = await http
            .post(
              Uri.parse(AppConstants.locationApiUrl),
              headers: {
                'Content-Type': 'application/json',
                'X-API-KEY': accessToken,
              },
              body: jsonEncode(data.toJson()),
            )
            .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('Location sent successfully: ${response.statusCode}');
          return true;
        } else {
          print('API error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error sending location (attempt $attempt): $e');

        // If this was the last attempt, return false
        if (attempt == AppConstants.maxRetries) {
          print('All retry attempts failed');
          return false;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return false;
  }
}
