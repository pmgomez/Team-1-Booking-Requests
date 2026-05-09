import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../models/anointing_sick_booking.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';

class AnointingSickService {
  static final AnointingSickService _instance = AnointingSickService._internal();
  factory AnointingSickService() => _instance;
  AnointingSickService._internal();

  Future<ApiResponse<List<AnointingSickBooking>>> getAllAnointingSickBookings({
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

      String endpoint = ApiConfig.anointingSickEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiConfig.getWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => AnointingSickBooking.fromJson(json))
            .toList();

        return ApiResponse<List<AnointingSickBooking>>(
          success: true,
          data: bookings,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<AnointingSickBooking>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch anointing bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<AnointingSickBooking>>(
        success: false,
        message: 'Network error fetching anointing bookings',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<AnointingSickBooking>> createAnointingSickBooking({
    required String token,
    required int parishId,
    required String sickPersonName,
    required String contactPersonName,
    required String contactEmail,
    required String contactPhone,
    required String location,
    String? locationAddress,
    String? preferredDate,
    String? preferredTimeSlot,
    int? priestId,
    List<Map<String, dynamic>>? notes,
  }) async {
    try {
      final requestBody = {
        'parishId': parishId,
        'sickPersonName': sickPersonName,
        'contactPersonName': contactPersonName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'location': location,
        if (locationAddress != null) 'locationAddress': locationAddress,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
        if (priestId != null) 'priestId': priestId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await ApiConfig.postWithAuth(
        ApiConfig.anointingSickEndpoint,
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final booking = AnointingSickBooking.fromJson(data['booking']);

        return ApiResponse<AnointingSickBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<AnointingSickBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to create anointing booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<AnointingSickBooking>(
        success: false,
        message: 'Network error creating anointing booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<AnointingSickBooking>> updateAnointingSickStatus({
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
        '${ApiConfig.anointingSickEndpoint}/$id/status',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = AnointingSickBooking.fromJson(data['booking']);

        return ApiResponse<AnointingSickBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<AnointingSickBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update anointing status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<AnointingSickBooking>(
        success: false,
        message: 'Network error updating anointing status',
        errors: [e.toString()],
      );
    }
  }

  // Get anointing sick booking by ID
  Future<ApiResponse<AnointingSickBooking>> getAnointingSickBookingById({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '${ApiConfig.anointingSickEndpoint}/$id',
        token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = AnointingSickBooking.fromJson(data['booking']);
        return ApiResponse<AnointingSickBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<AnointingSickBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch anointing booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<AnointingSickBooking>(
        success: false,
        message: 'Network error fetching anointing booking',
        errors: [e.toString()],
      );
    }
  }

  // Update anointing sick booking (full fields - admin)
  Future<ApiResponse<AnointingSickBooking>> updateAnointingSickBooking({
    required String token,
    required int id,
    String? sickPersonName,
    String? contactPersonName,
    String? contactEmail,
    String? contactPhone,
    String? location,
    String? locationAddress,
    String? preferredDate,
    String? preferredTimeSlot,
    String? preferredPriest,
    String? additionalNotes,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (sickPersonName != null) 'sickPersonName': sickPersonName,
        if (contactPersonName != null) 'contactPersonName': contactPersonName,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (location != null) 'location': location,
        if (locationAddress != null) 'locationAddress': locationAddress,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      final response = await ApiConfig.putWithAuth(
        '${ApiConfig.anointingSickEndpoint}/$id',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = AnointingSickBooking.fromJson(data['booking']);
        return ApiResponse<AnointingSickBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<AnointingSickBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to update anointing booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<AnointingSickBooking>(
        success: false,
        message: 'Network error updating anointing booking',
        errors: [e.toString()],
      );
    }
  }

  // Attach document to anointing sick booking
  Future<ApiResponse<Map<String, dynamic>>> attachDocumentToBooking({
    required int bookingId,
    required String token,
    required PlatformFile file,
    String? documentType,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.anointingSickEndpoint}/$bookingId/document');
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

  Future<ApiResponse<AnointingSickBooking>> resubmitBooking({
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
        '${ApiConfig.anointingSickEndpoint}/$id',
        token,
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = AnointingSickBooking.fromJson(data['booking']);
        return ApiResponse<AnointingSickBooking>(
          success: true,
          data: booking,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<AnointingSickBooking>(
          success: false,
          message: errorData['message'] ?? 'Failed to resubmit booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<AnointingSickBooking>(
        success: false,
        message: 'Network error resubmitting booking',
        errors: [e.toString()],
      );
    }
  }
}
