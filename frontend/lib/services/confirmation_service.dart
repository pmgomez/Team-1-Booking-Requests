import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
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
    int? priestId,
    List<Map<String, dynamic>>? notes,
    Map<String, dynamic>? baptismalCertificate,
    Map<String, dynamic>? birthCertificate,
  }) async {
    try {
      // Build documents array from provided certificate data
      List<Map<String, dynamic>> documents = [];
      if (baptismalCertificate != null) {
        documents.add({
          'uploadedFile': baptismalCertificate['filename'],
          'filePath': baptismalCertificate['path'],
          'fileUrl': baptismalCertificate['url'],
          'fileSize': baptismalCertificate['size'],
          'mimeType': baptismalCertificate['mimetype'],
          'documentType': 'baptismal_certificate',
        });
      }
      if (birthCertificate != null) {
        documents.add({
          'uploadedFile': birthCertificate['filename'],
          'filePath': birthCertificate['path'],
          'fileUrl': birthCertificate['url'],
          'fileSize': birthCertificate['size'],
          'mimeType': birthCertificate['mimetype'],
          'documentType': 'birth_certificate',
        });
      }

      final requestBody = {
        'parishId': parishId,
        'confirmandName': confirmandName,
        'fatherName': fatherName,
        'motherName': motherName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'preferredDate': preferredDate,
        'preferredTimeSlot': preferredTimeSlot,
        if (priestId != null) 'priestId': priestId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (documents.isNotEmpty) 'documents': documents,
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

  // Get confirmation booking by ID
  Future<ApiResponse<ConfirmationBooking>> getConfirmationBookingById({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '${ApiConfig.confirmationsEndpoint}/$id',
        token,
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
          message: errorData['message'] ?? 'Failed to fetch confirmation booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ConfirmationBooking>(
        success: false,
        message: 'Network error fetching confirmation booking',
        errors: [e.toString()],
      );
    }
  }

  // Update confirmation booking (full fields - admin)
  Future<ApiResponse<ConfirmationBooking>> updateConfirmationBooking({
    required String token,
    required int id,
    String? confirmandName,
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
        if (confirmandName != null) 'confirmandName': confirmandName,
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
        '${ApiConfig.confirmationsEndpoint}/$id',
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
          message: errorData['message'] ?? 'Failed to update confirmation booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ConfirmationBooking>(
        success: false,
        message: 'Network error updating confirmation booking',
        errors: [e.toString()],
      );
    }
  }

  // Attach document to confirmation booking
  Future<ApiResponse<Map<String, dynamic>>> attachDocumentToBooking({
    required int bookingId,
    required String token,
    required PlatformFile file,
    String? documentType,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.confirmationsEndpoint}/$bookingId/document');
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

  Future<ApiResponse<ConfirmationBooking>> resubmitBooking({
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
        '${ApiConfig.confirmationsEndpoint}/$id',
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
          message: errorData['message'] ?? 'Failed to resubmit booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ConfirmationBooking>(
        success: false,
        message: 'Network error resubmitting booking',
        errors: [e.toString()],
      );
    }
  }
}
