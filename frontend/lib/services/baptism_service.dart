import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/baptism_booking.dart';
import '../models/api_response.dart';
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
    String? uploadedFile,
    String? filePath,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    String? documentType,
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
        if (uploadedFile != null) 'uploadedFile': uploadedFile,
        if (filePath != null) 'filePath': filePath,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileSize != null) 'fileSize': fileSize,
        if (mimeType != null) 'mimeType': mimeType,
        if (documentType != null) 'documentType': documentType,
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

  // Update baptism booking (full fields - admin)
  Future<ApiResponse<BaptismBooking>> updateBaptismBooking({
    required int id,
    String? childFullName,
    String? dateOfBirth,
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
        if (childFullName != null) 'childFullName': childFullName,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (fatherName != null) 'fatherName': fatherName,
        if (motherName != null) 'motherName': motherName,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (additionalNotes != null) 'additionalNotes': additionalNotes,
      };

      print('=== UPDATE BAPTISM REQUEST ===');
      print('ID: $id');
      print('Request body: $requestBody');

      final response = await _apiClient.putWithAuth(
        '${ApiConfig.baptismsEndpoint}/$id',
        json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      print('ERROR in updateBaptismBooking: $e');
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

  // Attach document to baptism booking
  Future<ApiResponse<Map<String, dynamic>>> attachDocumentToBooking({
    required int bookingId,
    required String token,
    required String filePath,
    String? documentType,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.baptismsEndpoint}/$bookingId/document');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('document', filePath));
      
      if (documentType != null) {
        request.fields['documentType'] = documentType;
      }

      request.headers.addAll(ApiConfig.getAuthHeaders(token));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('Attach doc response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data['document'] ?? data,
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
      print('Error attaching document: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error attaching document: $e',
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
