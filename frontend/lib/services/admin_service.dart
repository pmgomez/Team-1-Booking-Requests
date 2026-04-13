import 'dart:convert';
import '../config/api_config.dart';
import '../models/api_response.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  // Get dashboard stats
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStats(String token) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '/api/admin/dashboard',
        token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to fetch dashboard stats',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }

  // Get all bookings with filters
  Future<ApiResponse<Map<String, dynamic>>> getAllBookings(
    String token, {
    String? sacramentType,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/api/admin/bookings?page=$page&limit=$limit';
      if (sacramentType != null) url += '&sacramentType=$sacramentType';
      if (status != null) url += '&status=$status';

      final response = await ApiConfig.getWithAuth(url, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to fetch bookings',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }

  // Approve/Decline booking
  Future<ApiResponse<Map<String, dynamic>>> updateBookingStatus(
    String token,
    String bookingId,
    String status, {
    String? adminNotes,
  }) async {
    try {
      final response = await ApiConfig.putWithAuth(
        '/api/admin/bookings/$bookingId/status',
        token,
        json.encode({
          'status': status,
          if (adminNotes != null) 'adminNotes': adminNotes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to update booking',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }

  // Get all parishes
  Future<ApiResponse<Map<String, dynamic>>> getAllParishes(String token) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '/api/parishes',
        token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to fetch parishes',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }

  // Create parish
  Future<ApiResponse<Map<String, dynamic>>> createParish(
    String token,
    Map<String, dynamic> parishData,
  ) async {
    try {
      final response = await ApiConfig.postWithAuth(
        '/api/parishes',
        token,
        json.encode(parishData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to create parish',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }

  // Get all users
  Future<ApiResponse<Map<String, dynamic>>> getAllUsers(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '/api/admin/users?page=$page&limit=$limit',
        token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to fetch users',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }

  // Create user
  Future<ApiResponse<Map<String, dynamic>>> createUser(
    String token,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await ApiConfig.postWithAuth(
        '/api/admin/users',
        token,
        json.encode(userData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to create user',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }

  // Get sacramental records
  Future<ApiResponse<Map<String, dynamic>>> getSacramentalRecords(
    String token, {
    String? sacramentType,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/api/sacramental-records?page=$page&limit=$limit';
      if (sacramentType != null) url += '&sacramentType=$sacramentType';

      final response = await ApiConfig.getWithAuth(url, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to fetch sacramental records',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error',
        errors: [e.toString()],
      );
    }
  }
}
