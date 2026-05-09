import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
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
    int? priestId,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? documents,
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
        if (priestId != null) 'priestId': priestId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (documents != null && documents.isNotEmpty) 'documents': documents,
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

  Future<ApiResponse<EucharistBooking>> getEucharistBookingById({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '${ApiConfig.eucharistEndpoint}/$id',
        token,
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
          message: errorData['message'] ?? 'Failed to fetch eucharist booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<EucharistBooking>(
        success: false,
        message: 'Network error fetching eucharist booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<EucharistBooking>> updateEucharistBooking({
    required String token,
    required int id,
    String? communicantName,
    String? fatherName,
    String? motherName,
    String? contactEmail,
    String? contactPhone,
    String? preferredDate,
    String? preferredTimeSlot,
    String? preferredPriest,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (communicantName != null) 'communicantName': communicantName,
        if (fatherName != null) 'fatherName': fatherName,
        if (motherName != null) 'motherName': motherName,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await ApiConfig.putWithAuth(
        '${ApiConfig.eucharistEndpoint}/$id',
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
          message: errorData['message'] ?? 'Failed to update eucharist booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<EucharistBooking>(
        success: false,
        message: 'Network error updating eucharist booking',
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

  Future<ApiResponse<void>> deleteEucharistBooking({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.deleteWithAuth(
        '${ApiConfig.eucharistEndpoint}/$id',
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(
          success: true,
          message: 'Eucharist booking cancelled successfully',
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: errorData['message'] ?? 'Failed to cancel eucharist booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error cancelling eucharist booking',
        errors: [e.toString()],
      );
    }
  }

  // Attach document to eucharist booking
  Future<ApiResponse<Map<String, dynamic>>> attachDocumentToBooking({
    required int bookingId,
    required String token,
    required PlatformFile file,
    String? documentType,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eucharistEndpoint}/$bookingId/document');
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('File bytes are null on web platform');
        }
        request.files.add(http.MultipartFile.fromBytes(
          'document',
          file.bytes!,
          filename: file.name,
        ));
      } else {
        if (file.path == null) {
          throw Exception('File path is null on mobile platform');
        }
        request.files.add(await http.MultipartFile.fromPath('document', file.path!));
      }

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

  Future<ApiResponse<EucharistBooking>> resubmitBooking({
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
        '${ApiConfig.eucharistEndpoint}/$id',
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
          message: errorData['message'] ?? 'Failed to resubmit booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<EucharistBooking>(
        success: false,
        message: 'Network error resubmitting booking',
        errors: [e.toString()],
      );
    }
  }
}
