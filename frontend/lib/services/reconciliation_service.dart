import 'dart:convert';
import '../models/reconciliation_booking.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';

class ReconciliationService {
  static final ReconciliationService _instance = ReconciliationService._internal();
  factory ReconciliationService() => _instance;
  ReconciliationService._internal();

  Future<ApiResponse<List<ReconciliationBooking>>> getAllReconciliationBookings({
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

      String endpoint = ApiConfig.reconciliationsEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiConfig.getWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => ReconciliationBooking.fromJson(json))
            .toList();

        return ApiResponse<List<ReconciliationBooking>>(
          success: true,
          data: bookings,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<ReconciliationBooking>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch reconciliation bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<ReconciliationBooking>>(
        success: false,
        message: 'Network error fetching reconciliation bookings',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<ReconciliationBooking>> createReconciliationBooking({
    required String token,
    required int parishId,
    required String penitentName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = {
        'parishId': parishId,
        'penitentName': penitentName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'preferredDate': preferredDate,
        'preferredTimeSlot': preferredTimeSlot,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await ApiConfig.postWithAuth(
        ApiConfig.reconciliationsEndpoint,
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final booking = ReconciliationBooking.fromJson(data['booking']);

        return ApiResponse<ReconciliationBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<ReconciliationBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to create reconciliation booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ReconciliationBooking>(
        success: false,
        message: 'Network error creating reconciliation booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<ReconciliationBooking>> updateReconciliationStatus({
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
        '${ApiConfig.reconciliationsEndpoint}/$id/status',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = ReconciliationBooking.fromJson(data['booking']);

        return ApiResponse<ReconciliationBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<ReconciliationBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update reconciliation status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ReconciliationBooking>(
        success: false,
        message: 'Network error updating reconciliation status',
        errors: [e.toString()],
      );
    }
  }
}
