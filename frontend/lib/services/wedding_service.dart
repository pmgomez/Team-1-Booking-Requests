import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
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
    int? priestId,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? documents,
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
        if (priestId != null) 'priestId': priestId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (documents != null && documents.isNotEmpty) 'documents': documents,
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

  Future<ApiResponse<void>> deleteWeddingBooking({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.deleteWithAuth(
        '${ApiConfig.weddingsEndpoint}/$id',
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(
          success: true,
          message: 'Wedding booking cancelled successfully',
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: errorData['message'] ?? 'Failed to cancel wedding booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error cancelling wedding booking',
        errors: [e.toString()],
      );
    }
  }

  // Attach document to wedding booking
  Future<ApiResponse<WeddingBooking>> updateWeddingBooking({
    required String token,
    required int id,
    String? groomFullName,
    String? brideFullName,
    String? contactEmail,
    String? contactPhone,
    String? preferredDate,
    String? preferredTimeSlot,
    String? seminarSchedule,
    String? preferredPriest,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (groomFullName != null) 'groomFullName': groomFullName,
        if (brideFullName != null) 'brideFullName': brideFullName,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
        if (seminarSchedule != null) 'seminarSchedule': seminarSchedule,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await ApiConfig.putWithAuth(
        '${ApiConfig.weddingsEndpoint}/$id',
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
          message: errorData['message'] ?? 'Failed to update wedding booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<WeddingBooking>(
        success: false,
        message: 'Network error updating wedding booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> attachDocumentToBooking({
    required int bookingId,
    required String token,
    required PlatformFile file,
    String? documentType,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weddingsEndpoint}/$bookingId/document');
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

  Future<ApiResponse<WeddingBooking>> resubmitBooking({
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
        '${ApiConfig.weddingsEndpoint}/$id',
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
          message: errorData['message'] ?? 'Failed to resubmit booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<WeddingBooking>(
        success: false,
        message: 'Network error resubmitting booking',
        errors: [e.toString()],
      );
    }
  }
}
