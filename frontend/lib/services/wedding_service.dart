import 'dart:convert';
import '../models/wedding_booking.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';

class WeddingService {
  static final WeddingService _instance = WeddingService._internal();
  factory WeddingService() => _instance;
  WeddingService._internal();

  Future<ApiResponse<List<WeddingBooking>>> getAllWeddingBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    int? parishId,
  }) async {
    try {
      List<String> queryParams = [];
      if (page != null) queryParams.add('page=$page');
      if (limit != null) queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');
      if (parishId != null) queryParams.add('parishId=$parishId');

      String endpoint = ApiConfig.weddingsEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiConfig.getWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => WeddingBooking.fromJson(json))
            .toList();

        return ApiResponse<List<WeddingBooking>>(
          success: true,
          data: bookings,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<WeddingBooking>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch wedding bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<WeddingBooking>>(
        success: false,
        message: 'Network error fetching wedding bookings',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<WeddingBooking>> getWeddingBookingById({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '${ApiConfig.weddingsEndpoint}/$id',
        token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = WeddingBooking.fromJson(data['booking']);

        return ApiResponse<WeddingBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<WeddingBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch wedding booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<WeddingBooking>(
        success: false,
        message: 'Network error fetching wedding booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<WeddingBooking>> createWeddingBooking({
    required String token,
    required int parishId,
    required String groomFullName,
    required String brideFullName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? seminarSchedule,
    String? preferredPriest,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = {
        'parishId': parishId,
        'groomFullName': groomFullName,
        'brideFullName': brideFullName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'preferredDate': preferredDate,
        'preferredTimeSlot': preferredTimeSlot,
        if (seminarSchedule != null) 'seminarSchedule': seminarSchedule,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await ApiConfig.postWithAuth(
        ApiConfig.weddingsEndpoint,
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final booking = WeddingBooking.fromJson(data['booking']);

        return ApiResponse<WeddingBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<WeddingBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to create wedding booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<WeddingBooking>(
        success: false,
        message: 'Network error creating wedding booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<WeddingBooking>> updateWeddingStatus({
    required String token,
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final requestBody = {
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
      };

      final response = await ApiConfig.patchWithAuth(
        '${ApiConfig.weddingsEndpoint}/$id/status',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = WeddingBooking.fromJson(data['booking']);

        return ApiResponse<WeddingBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<WeddingBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update wedding status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<WeddingBooking>(
        success: false,
        message: 'Network error updating wedding status',
        errors: [e.toString()],
      );
    }
  }
}
