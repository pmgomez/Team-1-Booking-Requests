import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/funeral_mass_booking.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';

class FuneralMassService {
  static final FuneralMassService _instance = FuneralMassService._internal();
  factory FuneralMassService() => _instance;
  FuneralMassService._internal();

  Future<ApiResponse<List<FuneralMassBooking>>> getAllFuneralMassBookings({
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

      String endpoint = ApiConfig.funeralMassEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiConfig.getWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => FuneralMassBooking.fromJson(json))
            .toList();

        return ApiResponse<List<FuneralMassBooking>>(
          success: true,
          data: bookings,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<FuneralMassBooking>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch funeral mass bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<FuneralMassBooking>>(
        success: false,
        message: 'Network error fetching funeral mass bookings',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<FuneralMassBooking>> createFuneralMassBooking({
    required String token,
    required int parishId,
    required String deceasedFullName,
    required String representativeName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? dateOfDeath,
    String? wakeStartDate,
    String? wakeEndDate,
    String? wakeLocation,
    int? priestId,
    List<Map<String, dynamic>>? notes,
  }) async {
    try {
      final requestBody = {
        'parishId': parishId,
        'deceasedFullName': deceasedFullName,
        'representativeName': representativeName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'preferredDate': preferredDate,
        'preferredTimeSlot': preferredTimeSlot,
        if (dateOfDeath != null) 'dateOfDeath': dateOfDeath,
        if (wakeStartDate != null) 'wakeStartDate': wakeStartDate,
        if (wakeEndDate != null) 'wakeEndDate': wakeEndDate,
        if (wakeLocation != null) 'wakeLocation': wakeLocation,
        if (priestId != null) 'priestId': priestId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await ApiConfig.postWithAuth(
        ApiConfig.funeralMassEndpoint,
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final booking = FuneralMassBooking.fromJson(data['booking']);

        return ApiResponse<FuneralMassBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<FuneralMassBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to create funeral mass booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<FuneralMassBooking>(
        success: false,
        message: 'Network error creating funeral mass booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<FuneralMassBooking>> updateFuneralMassStatus({
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
        '${ApiConfig.funeralMassEndpoint}/$id/status',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = FuneralMassBooking.fromJson(data['booking']);

        return ApiResponse<FuneralMassBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<FuneralMassBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update funeral mass status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<FuneralMassBooking>(
        success: false,
        message: 'Network error updating funeral mass status',
        errors: [e.toString()],
      );
    }
  }

  // Get funeral mass booking by ID
  Future<ApiResponse<FuneralMassBooking>> getFuneralMassBookingById({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '${ApiConfig.funeralMassEndpoint}/$id',
        token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = FuneralMassBooking.fromJson(data['booking']);
        return ApiResponse<FuneralMassBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<FuneralMassBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch funeral mass booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<FuneralMassBooking>(
        success: false,
        message: 'Network error fetching funeral mass booking',
        errors: [e.toString()],
      );
    }
  }

  // Update funeral mass booking (full fields - admin)
  Future<ApiResponse<FuneralMassBooking>> updateFuneralMassBooking({
    required String token,
    required int id,
    String? deceasedFullName,
    String? dateOfDeath,
    String? representativeName,
    String? contactEmail,
    String? contactPhone,
    String? wakeStartDate,
    String? wakeEndDate,
    String? wakeLocation,
    String? preferredDate,
    String? preferredTimeSlot,
    String? preferredPriest,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (deceasedFullName != null) 'deceasedFullName': deceasedFullName,
        if (dateOfDeath != null) 'dateOfDeath': dateOfDeath,
        if (representativeName != null) 'representativeName': representativeName,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (wakeStartDate != null) 'wakeStartDate': wakeStartDate,
        if (wakeEndDate != null) 'wakeEndDate': wakeEndDate,
        if (wakeLocation != null) 'wakeLocation': wakeLocation,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await ApiConfig.putWithAuth(
        '${ApiConfig.funeralMassEndpoint}/$id',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = FuneralMassBooking.fromJson(data['booking']);
        return ApiResponse<FuneralMassBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<FuneralMassBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update funeral mass booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<FuneralMassBooking>(
        success: false,
        message: 'Network error updating funeral mass booking',
        errors: [e.toString()],
      );
    }
  }

  // Attach document to funeral mass booking
  Future<ApiResponse<Map<String, dynamic>>> attachDocumentToBooking({
    required int bookingId,
    required String token,
    required String filePath,
    String? documentType,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.funeralMassEndpoint}/$bookingId/document');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('document', filePath));
      if (documentType != null) {
        request.fields['documentType'] = documentType;
      }
      request.headers.addAll(ApiConfig.getAuthHeaders(token));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data['document'],
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: errorData['message'] ?? 'Failed to attach document',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error attaching document',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<FuneralMassBooking>> resubmitBooking({
    required int id,
    required String token,
    List<Map<String, dynamic>>? notes,
  }) async {
    try {
      final requestBody = {
        'status': 'pending',
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      final response = await ApiConfig.putWithAuth(
        '${ApiConfig.funeralMassEndpoint}/$id',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = FuneralMassBooking.fromJson(data['booking']);
        return ApiResponse<FuneralMassBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<FuneralMassBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to resubmit booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<FuneralMassBooking>(
        success: false,
        message: 'Network error resubmitting booking',
        errors: [e.toString()],
      );
    }
  }
}
