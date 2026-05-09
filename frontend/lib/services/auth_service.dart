import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import '../config/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _mustChangePassword = false;
  bool get mustChangePassword => _mustChangePassword;

  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _googleSignInInstance {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
    return _googleSignIn!;
  }

  String? _accessToken;
  String? _refreshTokenValue;
  User? _currentUser;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshTokenValue;
  User? get currentUser => _currentUser;

  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  // Initialize the service with stored tokens
  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    _accessToken = prefs.getString(AppConstants.tokenKey);
    _refreshTokenValue = prefs.getString(AppConstants.refreshTokenKey);
    
    String? userData = prefs.getString(AppConstants.userKey);
    if (userData != null) {
      _currentUser = User.fromJson(json.decode(userData));
    }
  }

  // Register a new user
  Future<ApiResponse<User>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    int? preferredParishId,
  }) async {
    try {
      final response = await ApiConfig.post(ApiConfig.registerEndpoint, json.encode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'preferredParishId': preferredParishId,
      }));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Store user data and tokens
        await _storeUserData(data);
        
        return ApiResponse<User>(
          success: true,
          data: _currentUser,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<User>(
          success: false,
          message: errorData['message'] ?? errorData['error'],
          errors: errorData['details'] != null 
              ? List<String>.from(errorData['details'].map((e) => e['msg'])) 
              : [errorData['error'] ?? 'Registration failed'],
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: AppConstants.networkErrorMessage,
        errors: [e.toString()],
      );
    }
  }

  // Login user
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiConfig.post(ApiConfig.loginEndpoint, json.encode({
        'email': email,
        'password': password,
      }));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store user data and tokens
        await _storeUserData(data);
        
        return ApiResponse<User>(
          success: true,
          data: _currentUser,
          message: data['message'],
          mustChangePassword: data['mustChangePassword'] ?? false,
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<User>(
          success: false,
          message: errorData['message'] ?? errorData['error'],
          errors: [errorData['error'] ?? 'Login failed'],
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: AppConstants.networkErrorMessage,
        errors: [e.toString()],
      );
    }
  }

  // Google Sign-In
  Future<ApiResponse<User>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignInInstance.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return ApiResponse<User>(
          success: false,
          message: 'Google sign-in was canceled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Send the ID token to your backend
      final response = await ApiConfig.post('${ApiConfig.authEndpoint}/google', json.encode({
        'idToken': googleAuth.idToken,
      }));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store user data and tokens
        await _storeUserData(data);
        
        return ApiResponse<User>(
          success: true,
          data: _currentUser,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<User>(
          success: false,
          message: errorData['message'] ?? errorData['error'],
          errors: [errorData['error'] ?? 'Google sign-in failed'],
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: AppConstants.networkErrorMessage,
        errors: [e.toString()],
      );
    }
  }

  // Sign out from Google
  Future<void> signOutFromGoogle() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }

  // Logout user
  Future<void> logout() async {
    _accessToken = null;
    _refreshTokenValue = null;
    _currentUser = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.setBool(AppConstants.isLoggedInKey, false);
    
    // Also sign out from Google
    await signOutFromGoogle();
  }

  // Refresh access token
  Future<bool> refreshTokenValue() async {
    if (_refreshTokenValue == null) return false;

    try {
      final response = await ApiConfig.post(ApiConfig.refreshEndpoint, json.encode({
        'refreshToken': _refreshTokenValue,
      }));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['accessToken'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _accessToken!);

        return true;
      } else {
        // If refresh token is invalid, logout user
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    if (_accessToken == null) {
      return ApiResponse<User>(
        success: false,
        message: 'User not authenticated',
      );
    }

    try {
      final response = await ApiConfig.getWithAuth(ApiConfig.profileEndpoint, _accessToken!);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['user'];
        _currentUser = User.fromJson(data);
        _mustChangePassword = false; // Reset flag on successful fetch
        
        // Update stored user data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userKey, json.encode(data));

        return ApiResponse<User>(
          success: true,
          data: _currentUser,
        );
      } else if (response.statusCode == 401) {
        // Try to refresh token and retry
        bool refreshSuccess = await refreshTokenValue();
        if (refreshSuccess) {
          return await getCurrentUser(); // Retry after refresh
        } else {
          return ApiResponse<User>(
            success: false,
            message: AppConstants.unauthorizedErrorMessage,
          );
        }
      } else if (ApiConfig.isPasswordChangeRequired(response)) {
        // Password change required - set flag and return specific response
        _mustChangePassword = true;
        return ApiResponse<User>(
          success: false,
          message: 'Password change required',
          mustChangePassword: true,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: 'Failed to fetch user profile',
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: AppConstants.networkErrorMessage,
        errors: [e.toString()],
      );
    }
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    if (_accessToken == null) {
      return ApiResponse<User>(
        success: false,
        message: 'User not authenticated',
      );
    }

    try {
      final response = await ApiConfig.putWithAuth(
        ApiConfig.profileEndpoint, 
        _accessToken!,
        json.encode({
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['user'];
        _currentUser = User.fromJson(data);
        
        // Update stored user data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userKey, json.encode(data));

        return ApiResponse<User>(
          success: true,
          data: _currentUser,
          message: json.decode(response.body)['message'],
        );
      } else if (response.statusCode == 401) {
        // Try to refresh token and retry
        bool refreshSuccess = await refreshTokenValue();
        if (refreshSuccess) {
          return await updateProfile(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            address: address,
          ); // Retry after refresh
        } else {
          return ApiResponse<User>(
            success: false,
            message: AppConstants.unauthorizedErrorMessage,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<User>(
          success: false,
          message: errorData['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: AppConstants.networkErrorMessage,
        errors: [e.toString()],
      );
    }
  }

  // Change password
  Future<ApiResponse<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_accessToken == null) {
      return ApiResponse<void>(
        success: false,
        message: 'User not authenticated',
      );
    }

    try {
      final response = await ApiConfig.patchWithAuth(
        ApiConfig.changePasswordEndpoint, 
        _accessToken!,
        json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: json.decode(response.body)['message'],
        );
      } else if (response.statusCode == 401) {
        // Try to refresh token and retry
        bool refreshSuccess = await refreshTokenValue();
        if (refreshSuccess) {
          return await changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
          ); // Retry after refresh
        } else {
          return ApiResponse<void>(
            success: false,
            message: AppConstants.unauthorizedErrorMessage,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: errorData['message'] ?? 'Failed to change password',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: AppConstants.networkErrorMessage,
        errors: [e.toString()],
      );
    }
  }

  // Force password change on first login
  Future<ApiResponse<void>> forcePasswordChange({
    required String newPassword,
  }) async {
    if (_accessToken == null) {
      return ApiResponse<void>(
        success: false,
        message: 'User not authenticated',
      );
    }

    try {
      final response = await ApiConfig.postWithAuth(
        ApiConfig.forcePasswordChangeEndpoint,
        _accessToken!,
        json.encode({
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: json.decode(response.body)['message'],
        );
      } else if (response.statusCode == 401) {
        // Try to refresh token and retry
        bool refreshSuccess = await refreshTokenValue();
        if (refreshSuccess) {
          return await forcePasswordChange(
            newPassword: newPassword,
          ); // Retry after refresh
        } else {
          return ApiResponse<void>(
            success: false,
            message: AppConstants.unauthorizedErrorMessage,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: errorData['message'] ?? 'Failed to change password',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: AppConstants.networkErrorMessage,
        errors: [e.toString()],
      );
    }
  }

  // Store user data in preferences
  Future<void> _storeUserData(Map<String, dynamic> data) async {
    _accessToken = data['accessToken'];
    _refreshTokenValue = data['refreshToken'];
    _currentUser = User.fromJson(data['user']);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, _accessToken!);
    await prefs.setString(AppConstants.refreshTokenKey, _refreshTokenValue!);
    await prefs.setString(AppConstants.userKey, json.encode(data['user']));
    await prefs.setBool(AppConstants.isLoggedInKey, true);
  }
}