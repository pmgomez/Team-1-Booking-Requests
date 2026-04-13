import 'dart:convert';
import '../models/confirmation_booking.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';

class ConfirmationService {
  static final ConfirmationService _instance = ConfirmationService._internal();
  factory ConfirmationService() => _instance;
  ConfirmationService._internal();

  Future<ApiResponse<List<ConfirmationBooking>>> getAllConfirmationBookings({
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

      String endpoint = ApiConfig.confirmationsEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiConfig.getWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => ConfirmationBooking.fromJson(json))
            .toList();

        return ApiResponse<List<ConfirmationBooking>>(
          success: true,
          data: bookings,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<ConfirmationBooking>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch confirmation bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<ConfirmationBooking>>(
        success: false,
        message: 'Network error fetching confirmation bookings',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<ConfirmationBooking>> createConfirmationBooking({
    required String token,
    required int parishId,
    required String confirmandName,
    required String fatherName,
    required String motherName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? preferredPriest,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = {
        'parishId': parishId,
        'confirmandName': confirmandName,
        'fatherName': fatherName,
        'motherName': motherName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'preferredDate': preferredDate,
        'preferredTimeSlot': preferredTimeSlot,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await ApiConfig.postWithAuth(
        ApiConfig.confirmationsEndpoint,
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final booking = ConfirmationBooking.fromJson(data['booking']);

        return ApiResponse<ConfirmationBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<ConfirmationBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to create confirmation booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ConfirmationBooking>(
        success: false,
        message: 'Network error creating confirmation booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<ConfirmationBooking>> updateConfirmationStatus({
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
        '${ApiConfig.confirmationsEndpoint}/$id/status',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = ConfirmationBooking.fromJson(data['booking']);

        return ApiResponse<ConfirmationBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<ConfirmationBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update confirmation status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ConfirmationBooking>(
        success: false,
        message: 'Network error updating confirmation status',
        errors: [e.toString()],
      );
    }
  }
}
