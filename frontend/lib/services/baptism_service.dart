import 'dart:convert';

import '../models/baptism_booking.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class BaptismService {
  static final BaptismService _instance = BaptismService._internal();
  factory BaptismService() => _instance;
  BaptismService._internal();

  final ApiClient _apiClient = ApiClient();

  // Get all baptism bookings
  Future<ApiResponse<List<BaptismBooking>>> getAllBaptismBookings({
    int? page,
    int? limit,
    String? status,
    int? parishId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Build query parameters
      List<String> queryParams = [];
      if (page != null) queryParams.add('page=$page');
      if (limit != null) queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');
      if (parishId != null) queryParams.add('parishId=$parishId');
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');

      String endpoint = ApiConfig.baptismsEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await _apiClient.getWithAuth(endpoint);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => BaptismBooking.fromJson(json))
            .toList();

        return ApiResponse<List<BaptismBooking>>(
          success: true,
          data: bookings,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<BaptismBooking>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch baptism bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<BaptismBooking>>(
        success: false,
        message: 'Network error fetching baptism bookings',
        errors: [e.toString()],
      );
    }
  }

  // Get baptism booking by ID
  Future<ApiResponse<BaptismBooking>> getBaptismBookingById({
    required int id,
  }) async {
    try {
      final response = await _apiClient.getWithAuth(
        '${ApiConfig.baptismsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = BaptismBooking.fromJson(data['booking']);

        return ApiResponse<BaptismBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<BaptismBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch baptism booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<BaptismBooking>(
        success: false,
        message: 'Network error fetching baptism booking',
        errors: [e.toString()],
      );
    }
  }

  // Create baptism booking
  Future<ApiResponse<BaptismBooking>> createBaptismBooking({
    required int parishId,
    required String childFullName,
    required String dateOfBirth,
    required String fatherName,
    required String motherName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? preferredPriest,
    String? additionalNotes,
    List<Map<String, String>>? godparents,
  }) async {
    try {
      final requestBody = {
        'parishId': parishId,
        'childFullName': childFullName,
        'dateOfBirth': dateOfBirth,
        'fatherName': fatherName,
        'motherName': motherName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'preferredDate': preferredDate,
        'preferredTimeSlot': preferredTimeSlot,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
        if (godparents != null) 'godparents': godparents,
      };

      final response = await _apiClient.postWithAuth(
        ApiConfig.baptismsEndpoint,
        json.encode(requestBody),
      );

      print('Baptism booking response status: ${response.statusCode}');
      print('Baptism booking response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Parsed baptism booking data: $data');
        final booking = BaptismBooking.fromJson(data['booking']);

        return ApiResponse<BaptismBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<BaptismBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to create baptism booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('Error creating baptism booking: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse<BaptismBooking>(
        success: false,
        message: 'Network error creating baptism booking: $e',
        errors: [e.toString()],
      );
    }
  }

  // Update baptism booking
  Future<ApiResponse<BaptismBooking>> updateBaptismBooking({
    required int id,
    String? status,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = {
        if (status != null) 'status': status,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await _apiClient.putWithAuth(
        '${ApiConfig.baptismsEndpoint}/$id',
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = BaptismBooking.fromJson(data['booking']);

        return ApiResponse<BaptismBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<BaptismBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update baptism booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<BaptismBooking>(
        success: false,
        message: 'Network error updating baptism booking',
        errors: [e.toString()],
      );
    }
  }

  // Update baptism booking status (Admin only)
  Future<ApiResponse<BaptismBooking>> updateBaptismStatus({
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final requestBody = {
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
      };

      final response = await _apiClient.patchWithAuth(
        '${ApiConfig.baptismsEndpoint}/$id/status',
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = BaptismBooking.fromJson(data['booking']);

        return ApiResponse<BaptismBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<BaptismBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update baptism status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<BaptismBooking>(
        success: false,
        message: 'Network error updating baptism status',
        errors: [e.toString()],
      );
    }
  }

  // Cancel baptism booking
  Future<ApiResponse<void>> cancelBaptismBooking({
    required int id,
  }) async {
    try {
      final response = await _apiClient.deleteWithAuth(
        '${ApiConfig.baptismsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<void>(
          success: true,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: errorData['message'] ?? 'Failed to cancel baptism booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error canceling baptism booking',
        errors: [e.toString()],
      );
    }
  }

  // Get available slots for baptism
  Future<ApiResponse<List<Map<String, dynamic>>>> getAvailableSlots({
    required int parishId,
    required String date,
  }) async {
    try {
      final endpoint = '${ApiConfig.baptismsEndpoint}/available-slots?parishId=$parishId&date=$date';
      final response = await ApiConfig.get(endpoint);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timeSlots = (data['timeSlots'] as List)
            .map((json) => Map<String, dynamic>.from(json))
            .toList();

        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: timeSlots,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch available slots',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Network error fetching available slots',
        errors: [e.toString()],
      );
    }
  }
}
