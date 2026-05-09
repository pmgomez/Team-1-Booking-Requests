import 'dart:convert';
import '../models/mass_intention.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class MassIntentionService {
  static final MassIntentionService _instance = MassIntentionService._internal();
  factory MassIntentionService() => _instance;
  MassIntentionService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<MassIntention>>> getAllMassIntentions({
    int? page,
    int? limit,
    String? status,
    int? parishId,
    String? type,
  }) async {
    try {
      List<String> queryParams = [];
      if (page != null) queryParams.add('page=$page');
      if (limit != null) queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');
      if (parishId != null) queryParams.add('parishId=$parishId');
      if (type != null) queryParams.add('type=$type');

      String endpoint = ApiConfig.massIntentionsEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await _apiClient.getWithAuth(endpoint);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final intentions = (data['intentions'] as List)
            .map((json) => MassIntention.fromJson(json))
            .toList();

        return ApiResponse<List<MassIntention>>(
          success: true,
          data: intentions,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<MassIntention>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch mass intentions',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<MassIntention>>(
        success: false,
        message: 'Network error fetching mass intentions',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<MassIntention>> getMassIntentionById({
    required int id,
  }) async {
    try {
      print('Fetching mass intention by ID: $id');
      print('Endpoint: ${ApiConfig.massIntentionsEndpoint}/$id');
      final response = await _apiClient.getWithAuth(
        '${ApiConfig.massIntentionsEndpoint}/$id',
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');
        final intention = MassIntention.fromJson(data['intention'] ?? data['massIntention'] ?? data);

        return ApiResponse<MassIntention>(
          success: true,
          data: intention,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<MassIntention>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch mass intention',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Exception fetching mass intention: $e');
      return ApiResponse<MassIntention>(
        success: false,
        message: 'Network error fetching mass intention: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<MassIntention>> createMassIntention({
    required String type,
    required String intentionDetails,
    required String donorName,
    required String dateRequested,
    required int parishId,
    required String massSchedule,
    String? preferredTime,
    String? preferredPriest,
    List<Map<String, dynamic>>? notes,
  }) async {
    try {
      final requestBody = {
        'type': type,
        'intentionDetails': intentionDetails,
        'donorName': donorName,
        'dateRequested': dateRequested,
        'parishId': parishId,
        'massSchedule': massSchedule,
        if (preferredTime != null) 'preferredTime': preferredTime,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.postWithAuth(
        ApiConfig.massIntentionsEndpoint,
        json.encode(requestBody),
      );

      print('Mass Intention response status: ${response.statusCode}');
      print('Mass Intention response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Parsed mass intention data: $data');
        final intention = MassIntention.fromJson(data['intention'] ?? data['massIntention'] ?? data);

        return ApiResponse<MassIntention>(
          success: true,
          data: intention,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<MassIntention>(
          success: false,
          message: errorData['message'] ?? 'Failed to create mass intention',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('Error creating mass intention: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse<MassIntention>(
        success: false,
        message: 'Network error creating mass intention: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<MassIntention>> updateMassIntention({
    required int id,
    required String type,
    required String intentionDetails,
    required String donorName,
    required String dateRequested,
    required String massSchedule,
    String? preferredTime,
    String? preferredPriest,
    List<Map<String, dynamic>>? notes,
  }) async {
    try {
      final requestBody = {
        'type': type,
        'intentionDetails': intentionDetails,
        'donorName': donorName,
        'dateRequested': dateRequested,
        'massSchedule': massSchedule,
        if (preferredTime != null) 'preferredTime': preferredTime,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.putWithAuth(
        '${ApiConfig.massIntentionsEndpoint}/$id',
        json.encode(requestBody),
      );

      print('Update mass intention response status: ${response.statusCode}');
      print('Update mass intention response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final intention = MassIntention.fromJson(data['intention'] ?? data['massIntention'] ?? data);

        return ApiResponse<MassIntention>(
          success: true,
          data: intention,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<MassIntention>(
          success: false,
          message: errorData['message'] ?? 'Failed to update mass intention',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('Error updating mass intention: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse<MassIntention>(
        success: false,
        message: 'Network error updating mass intention: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<MassIntention>> updateMassIntentionStatus({
    required int id,
    required String status,
    List<Map<String, dynamic>>? notes,
  }) async {
    try {
      print('Updating mass intention $id status to: $status');
      final requestBody = {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.patchWithAuth(
        '${ApiConfig.massIntentionsEndpoint}/$id/status',
        json.encode(requestBody),
      );

      print('Update status response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed update response: $data');
        final intention = MassIntention.fromJson(data['intention'] ?? data);

        return ApiResponse<MassIntention>(
          success: true,
          data: intention,
          message: data['message'] ?? 'Status updated successfully',
        );
      } else {
        final errorData = json.decode(response.body);
        print('Error response: $errorData');
        return ApiResponse<MassIntention>(
          success: false,
          message: errorData['message'] ?? errorData['error'] ?? 'Failed to update mass intention status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Exception updating status: $e');
      return ApiResponse<MassIntention>(
        success: false,
        message: 'Network error updating mass intention status: $e',
        errors: [e.toString()],
      );
    }
  }
}
