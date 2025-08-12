import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    String? message,
    T? data,
    String? error,
    int? statusCode,
  }) = _ApiResponse<T>;
  
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}

@freezed
class HealthCheckResponse with _$HealthCheckResponse {
  const factory HealthCheckResponse({
    required String status,
    required String timestamp,
    required int activeSessions,
    required bool databaseConnected,
    required String databricksStatus,
    required bool mobileSupport,
    required String serverVersion,
    required Map<String, bool> features,
  }) = _HealthCheckResponse;
  
  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) => _$HealthCheckResponseFromJson(json);
}
