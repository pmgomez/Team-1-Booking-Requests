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
      final response = await _apiClient.getWithAuth(
        '${ApiConfig.massIntentionsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final intention = MassIntention.fromJson(data['intention']);

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
      return ApiResponse<MassIntention>(
        success: false,
        message: 'Network error fetching mass intention',
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
    String? preferredPriest,
    String? notes,
  }) async {
    try {
      final requestBody = {
        'type': type,
        'intentionDetails': intentionDetails,
        'donorName': donorName,
        'dateRequested': dateRequested,
        'parishId': parishId,
        'massSchedule': massSchedule,
        if (preferredPriest != null) 'preferredPriest': preferredPriest,
        if (notes != null) 'notes': notes,
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

  Future<ApiResponse<MassIntention>> updateMassIntentionStatus({
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
        '${ApiConfig.massIntentionsEndpoint}/$id/status',
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final intention = MassIntention.fromJson(data['intention']);

        return ApiResponse<MassIntention>(
          success: true,
          data: intention,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<MassIntention>(
          success: false,
          message: errorData['message'] ?? 'Failed to update mass intention status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<MassIntention>(
        success: false,
        message: 'Network error updating mass intention status',
        errors: [e.toString()],
      );
    }
  }
}
