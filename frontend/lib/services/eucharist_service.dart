import 'dart:convert';
import '../models/eucharist_booking.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';

class EucharistService {
  static final EucharistService _instance = EucharistService._internal();
  factory EucharistService() => _instance;
  EucharistService._internal();

  Future<ApiResponse<List<EucharistBooking>>> getAllEucharistBookings({
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

      String endpoint = ApiConfig.eucharistEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiConfig.getWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => EucharistBooking.fromJson(json))
            .toList();

        return ApiResponse<List<EucharistBooking>>(
          success: true,
          data: bookings,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<EucharistBooking>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch eucharist bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<EucharistBooking>>(
        success: false,
        message: 'Network error fetching eucharist bookings',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<EucharistBooking>> createEucharistBooking({
    required String token,
    required int parishId,
    required String communicantName,
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
        'communicantName': communicantName,
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
        ApiConfig.eucharistEndpoint,
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final booking = EucharistBooking.fromJson(data['booking']);

        return ApiResponse<EucharistBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<EucharistBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to create eucharist booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<EucharistBooking>(
        success: false,
        message: 'Network error creating eucharist booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<EucharistBooking>> updateEucharistStatus({
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
        '${ApiConfig.eucharistEndpoint}/$id/status',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = EucharistBooking.fromJson(data['booking']);

        return ApiResponse<EucharistBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<EucharistBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update eucharist status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<EucharistBooking>(
        success: false,
        message: 'Network error updating eucharist status',
        errors: [e.toString()],
      );
    }
  }
}
