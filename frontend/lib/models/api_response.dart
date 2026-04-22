class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final List<String>? errors;
  final bool mustChangePassword;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
    this.mustChangePassword = false,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? dataMapper
  ) {
    return ApiResponse(
      success: json['success'] ?? json['status'] == 'success' ?? false,
      data: dataMapper != null && json['data'] != null
          ? dataMapper(json['data'])
          : null,
      message: json['message'] ?? json['error'],
      statusCode: json['statusCode'] ?? json['status_code'],
      errors: json['errors'] != null
          ? List<String>.from(json['errors'])
          : json['details'] != null && json['details'] is List
              ? List<String>.from(
                  (json['details'] as List).map((e) => e.toString()))
              : null,
      mustChangePassword: json['mustChangePassword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'statusCode': statusCode,
      'errors': errors,
      'mustChangePassword': mustChangePassword,
    };
  }
}