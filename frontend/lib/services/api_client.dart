import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../config/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // Get current access token
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Get current refresh token
  Future<String?> _getRefreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  // Save tokens
  Future<void> _saveTokens({String? accessToken, String? refreshToken}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString(AppConstants.tokenKey, accessToken);
    }
    if (refreshToken != null) {
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
    }
  }

  // Refresh access token
  Future<bool> _refreshToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await ApiConfig.post(
        ApiConfig.refreshEndpoint,
        json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      } else {
        // Refresh failed - clear tokens
        await _clearTokens();
        return false;
      }
    } catch (e) {
      await _clearTokens();
      return false;
    }
  }

  // Clear tokens
  Future<void> _clearTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  // GET request with auto-refresh
  Future<http.Response> getWithAuth(String endpoint) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('No access token. Please login.');
    }

    var response = await ApiConfig.getWithAuth(endpoint, token);

    if (response.statusCode == 401) {
      // Token expired, try to refresh
      final refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getToken();
        if (token != null) {
          response = await ApiConfig.getWithAuth(endpoint, token);
        }
      }
    }

    return response;
  }

  Future<http.Response> postWithAuth(String endpoint, dynamic body) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('No access token. Please login.');
    }

    print('[api_client.postWithAuth] endpoint: $endpoint, body type: ${body.runtimeType}, body: $body');

    var response = await ApiConfig.postWithAuth(endpoint, token, body);

    if (response.statusCode == 401) {
      // Token expired, try to refresh
      final refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getToken();
        if (token != null) {
          response = await ApiConfig.postWithAuth(endpoint, token, body);
        }
      }
    }

    return response;
  }

  // PUT request with auto-refresh
  Future<http.Response> putWithAuth(String endpoint, dynamic body) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('No access token. Please login.');
    }

    var response = await ApiConfig.putWithAuth(endpoint, token, body);

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getToken();
        if (token != null) {
          response = await ApiConfig.putWithAuth(endpoint, token, body);
        }
      }
    }

    return response;
  }

  // PATCH request with auto-refresh
  Future<http.Response> patchWithAuth(String endpoint, dynamic body) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('No access token. Please login.');
    }

    var response = await ApiConfig.patchWithAuth(endpoint, token, body);

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getToken();
        if (token != null) {
          response = await ApiConfig.patchWithAuth(endpoint, token, body);
        }
      }
    }

    return response;
  }

  // DELETE request with auto-refresh
  Future<http.Response> deleteWithAuth(String endpoint) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('No access token. Please login.');
    }

    var response = await ApiConfig.deleteWithAuth(endpoint, token);

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getToken();
        if (token != null) {
          response = await ApiConfig.deleteWithAuth(endpoint, token);
        }
      }
    }

    return response;
  }
}
