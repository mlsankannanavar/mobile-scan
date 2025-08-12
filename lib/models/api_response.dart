class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data']) 
          : json['data'],
      error: json['error'],
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
    'error': error,
    'statusCode': statusCode,
  };
}

class HealthCheckResponse {
  final String status;
  final String timestamp;
  final int activeSessions;
  final bool databaseConnected;
  final String databricksStatus;
  final bool mobileSupport;
  final String serverVersion;
  final Map<String, bool> features;

  const HealthCheckResponse({
    required this.status,
    required this.timestamp,
    required this.activeSessions,
    required this.databaseConnected,
    required this.databricksStatus,
    required this.mobileSupport,
    required this.serverVersion,
    required this.features,
  });

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) {
    return HealthCheckResponse(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] ?? '',
      activeSessions: json['activeSessions'] ?? 0,
      databaseConnected: json['databaseConnected'] ?? false,
      databricksStatus: json['databricksStatus'] ?? '',
      mobileSupport: json['mobileSupport'] ?? false,
      serverVersion: json['serverVersion'] ?? '',
      features: Map<String, bool>.from(json['features'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'timestamp': timestamp,
    'activeSessions': activeSessions,
    'databaseConnected': databaseConnected,
    'databricksStatus': databricksStatus,
    'mobileSupport': mobileSupport,
    'serverVersion': serverVersion,
    'features': features,
  };
}
