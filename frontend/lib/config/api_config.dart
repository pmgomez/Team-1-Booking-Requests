import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_constants.dart';

class ApiConfig {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Headers
  static Map<String, String> get baseHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Endpoints
  static const String authEndpoint = '/api/auth';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String refreshEndpoint = '$authEndpoint/refresh';
  static const String profileEndpoint = '$authEndpoint/me';
  static const String changePasswordEndpoint = '$authEndpoint/change-password';
  static const String forcePasswordChangeEndpoint = '$authEndpoint/force-password-change';

  static const String bookingsEndpoint = '/api/bookings';
  static const String intentionsEndpoint = '/api/intentions';
  static const String usersEndpoint = '/api/users';
  static const String filesEndpoint = '/api/files';
  static const String parishesEndpoint = '/api/parishes';

  // Sacrament endpoints
  static const String baptismsEndpoint = '/api/baptisms';
  static const String weddingsEndpoint = '/api/sacraments/weddings';
  static const String confirmationsEndpoint = '/api/sacraments/confirmations';
  static const String eucharistEndpoint = '/api/sacraments/eucharist';
  static const String reconciliationsEndpoint = '/api/sacraments/reconciliations';
  static const String anointingSickEndpoint = '/api/sacraments/anointing-sick';
  static const String funeralMassEndpoint = '/api/sacraments/funeral-mass';
  static const String massIntentionsEndpoint = '/api/mass-intentions';

  static const String healthEndpoint = '/health';
  static const String apiInfoEndpoint = '/api';

  // Helper to refresh token
  static Future<String?> _refreshToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final refreshTokenValue = prefs.getString(AppConstants.refreshTokenKey);

      if (refreshTokenValue == null) return null;

      final response = await post(refreshEndpoint, json.encode({
        'refreshToken': refreshTokenValue,
      }));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['accessToken'];

        // Save new access token
        await prefs.setString(AppConstants.tokenKey, newAccessToken);

        return newAccessToken;
      } else {
        // Refresh failed - clear session
        await prefs.remove(AppConstants.tokenKey);
        await prefs.remove(AppConstants.refreshTokenKey);
        await prefs.remove(AppConstants.userKey);
        await prefs.setBool(AppConstants.isLoggedInKey, false);
        return null;
      }
    } catch (e) {
      print('Token refresh error: $e');
      return null;
    }
  }

  // HTTP Methods with Authorization and auto-refresh
  static Future<http.Response> getWithAuth(String endpoint, String token, {bool retried = false}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = getAuthHeaders(token);

    final response = await http.get(uri, headers: headers).timeout(AppConstants.apiTimeout);

    // If 401 and not already retried, try to refresh token
    if (response.statusCode == 401 && !retried) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        return getWithAuth(endpoint, newToken, retried: true);
      }
    }

    return response;
  }

  static Future<http.Response> postWithAuth(String endpoint, String token, dynamic body, {bool retried = false}) async {
    print('[ApiConfig.postWithAuth] endpoint: $endpoint, body type: ${body.runtimeType}, body: $body');
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = getAuthHeaders(token);

    final response = await http.post(uri, headers: headers, body: body).timeout(AppConstants.apiTimeout);

    // If 401 and not already retried, try to refresh token
    if (response.statusCode == 401 && !retried) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        return postWithAuth(endpoint, newToken, body, retried: true);
      }
    }

    return response;
  }

  static Future<http.Response> putWithAuth(String endpoint, String token, dynamic body, {bool retried = false}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = getAuthHeaders(token);

    final response = await http.put(uri, headers: headers, body: body).timeout(AppConstants.apiTimeout);

    // If 401 and not already retried, try to refresh token
    if (response.statusCode == 401 && !retried) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        return putWithAuth(endpoint, newToken, body, retried: true);
      }
    }

    return response;
  }

  static Future<http.Response> patchWithAuth(String endpoint, String token, dynamic body, {bool retried = false}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = getAuthHeaders(token);

    final response = await http.patch(uri, headers: headers, body: body).timeout(AppConstants.apiTimeout);

    // If 401 and not already retried, try to refresh token
    if (response.statusCode == 401 && !retried) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        return patchWithAuth(endpoint, newToken, body, retried: true);
      }
    }

    return response;
  }

  static Future<http.Response> deleteWithAuth(String endpoint, String token, {bool retried = false}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = getAuthHeaders(token);

    final response = await http.delete(uri, headers: headers).timeout(AppConstants.apiTimeout);

    // If 401 and not already retried, try to refresh token
    if (response.statusCode == 401 && !retried) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        return deleteWithAuth(endpoint, newToken, retried: true);
      }
    }

    return response;
  }

  // Check if response indicates password change required
  static bool isPasswordChangeRequired(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final data = json.decode(response.body);
        return data['mustChangePassword'] == true ||
               data['error'] == 'Password change required';
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  // Public HTTP Methods
  static Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return http.get(uri, headers: baseHeaders).timeout(AppConstants.apiTimeout);
  }
  
  static Future<http.Response> post(String endpoint, dynamic body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return http.post(uri, headers: baseHeaders, body: body).timeout(AppConstants.apiTimeout);
  }
  
  // File upload with authorization
  static Future<http.StreamedResponse> uploadFile(
    String endpoint, 
    String token, 
    File file, 
    String fieldName,
    {Map<String, String>? additionalFields}
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    // Add authorization header
    request.headers.addAll(getAuthHeaders(token));
    
    // Add file
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    
    // Add additional fields if provided
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }
    
    return request.send().timeout(AppConstants.apiTimeout);
  }
}