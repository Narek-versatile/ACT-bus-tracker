import 'dart:convert';
import 'dart:math';
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

      // 1. Get JWT token
      final response1 = await http
          .post(
            Uri.parse(AppConstants.loginApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonBody,
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

      if (response1.statusCode >= 200 && response1.statusCode < 300) {
        String accessToken = '';
        try {
          final data1 = jsonDecode(response1.body);
          if (data1 is Map<String, dynamic>) {
            accessToken = data1['access'] ?? '';
          }
        } catch (_) {}

        if (accessToken.isNotEmpty) {
          // 2. Get X-API-TOKEN
          final response2 = await http
              .post(
                Uri.parse(AppConstants.tokenApiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $accessToken',
                },
              )
              .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

          if (response2.statusCode >= 200 && response2.statusCode < 300) {
            String xApiToken = '';
            try {
              final data2 = jsonDecode(response2.body);
              if (data2 is Map<String, dynamic>) {
                xApiToken = data2['token'] ?? '';
              }
            } catch (_) {}

            if (xApiToken.isNotEmpty) {
              final storage = StorageService();
              await storage.saveAuthTokens(login, xApiToken, '');
              return true;
            } else {
              print('X-API-TOKEN not found in response');
            }
          } else {
            print(
              'Error getting X-API-TOKEN: ${response2.statusCode} - ${response2.body}',
            );
          }
        } else {
          print('JWT token not found in response');
        }
      } else {
        print(
          'Error getting JWT token: ${response1.statusCode} - ${response1.body}',
        );
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
