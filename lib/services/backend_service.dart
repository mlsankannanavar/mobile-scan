import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/batch_info.dart';
import '../models/match_result.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;
  
  ApiException(this.message, {this.statusCode, this.details});
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class BackendService {
  static const String _baseUrl = Constants.baseUrl;
  static const Duration _timeout = Constants.connectionTimeout;
  
  late final http.Client _client;
  
  BackendService() {
    _client = http.Client();
  }
  
  void dispose() {
    _client.close();
  }
  
  /// Get default headers for mobile requests
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'BatchMate-Mobile/1.0.0 (Android; Flutter)',
    'X-Requested-With': 'BatchMate-Mobile',
    'X-Client-Type': 'mobile-app',
    'X-Client-Platform': 'android',
    'Cache-Control': 'no-cache',
  };
  
  /// Test server connection and get health status
  Future<bool> testConnection() async {
    try {
      AppLogger.info('Testing server connection...');
      
      final stopwatch = Stopwatch()..start();
      final response = await _client
          .get(
            Uri.parse('$_baseUrl${Constants.healthEndpoint}'),
            headers: _defaultHeaders,
          )
          .timeout(_timeout);
          
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final healthResponse = HealthCheckResponse.fromJson(data);
        
        AppLogger.info(
          'Server connection successful',
          details: {
            'responseTime': '${stopwatch.elapsedMilliseconds}ms',
            'status': healthResponse.status,
            'mobileSupport': healthResponse.mobileSupport,
            'serverVersion': healthResponse.serverVersion,
          },
        );
        
        return healthResponse.status == 'healthy' && healthResponse.mobileSupport;
      } else {
        AppLogger.error(
          'Health check failed',
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Connection test failed', details: {'error': e.toString()});
      return false;
    }
  }
  
  /// Get filtered batches for a session
  Future<Map<String, BatchInfo>> getFilteredBatches(String sessionId) async {
    try {
      AppLogger.info('Downloading filtered batches for session: $sessionId');
      
      final stopwatch = Stopwatch()..start();
      final response = await _client
          .get(
            Uri.parse('$_baseUrl${Constants.filteredBatchesEndpoint}/$sessionId'),
            headers: _defaultHeaders,
          )
          .timeout(_timeout);
          
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final batchesData = data['batches'] as Map<String, dynamic>;
          final batches = <String, BatchInfo>{};
          
          for (final entry in batchesData.entries) {
            final batchData = entry.value as Map<String, dynamic>;
            batches[entry.key] = BatchInfo(
              batchNumber: entry.key,
              expiryDate: batchData['expiry_date'] ?? '',
              itemName: batchData['item_name'] ?? '',
              itemCode: batchData['item_code'] ?? '',
              locationCode: batchData['location_code'] ?? '',
            );
          }
          
          AppLogger.info(
            'Downloaded batches successfully',
            details: {
              'sessionId': sessionId,
              'count': batches.length,
              'downloadTime': '${stopwatch.elapsedMilliseconds}ms',
            },
          );
          
          return batches;
        } else {
          throw ApiException(
            data['message'] ?? 'Failed to fetch batches',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Session not found. Please ensure item codes are set first.',
          statusCode: 404,
        );
      } else {
        throw ApiException(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
          details: {'body': response.body},
        );
      }
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException {
      throw ApiException('Network error occurred');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to download batches: ${e.toString()}');
    }
  }
  
  /// Submit final batch result to server
  Future<bool> submitFinalBatch(
    String sessionId, {
    required String batchNumber,
    required int quantity,
    required double confidence,
    required String matchType,
    required String extractedText,
    List<MatchResult>? alternativeMatches,
  }) async {
    try {
      AppLogger.info('Submitting batch to server', details: {
        'sessionId': sessionId,
        'batchNumber': batchNumber,
        'quantity': quantity,
        'confidence': confidence,
        'matchType': matchType,
      });
      
      // Generate capture ID
      final captureId = 'cap_${DateTime.now().millisecondsSinceEpoch}';
      
      // Convert alternative matches to API format
      final altMatches = alternativeMatches?.map((match) => {
        'batch': match.batchNumber,
        'confidence': match.confidence,
      }).toList();
      
      final requestBody = {
        'batchNumber': batchNumber,
        'quantity': quantity,
        'confidence': confidence,
        'matchType': matchType,
        'captureId': captureId,
        'submitTimestamp': DateTime.now().millisecondsSinceEpoch,
        'extractedText': extractedText,
        'selectedFromOptions': alternativeMatches != null && alternativeMatches.isNotEmpty,
        if (altMatches != null) 'alternativeMatches': altMatches,
      };
      
      final stopwatch = Stopwatch()..start();
      final response = await _client
          .post(
            Uri.parse('$_baseUrl${Constants.submitMobileBatchEndpoint}/$sessionId'),
            headers: _defaultHeaders,
            body: json.encode(requestBody),
          )
          .timeout(_timeout);
          
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          AppLogger.info(
            'Batch submitted successfully',
            details: {
              'sessionId': sessionId,
              'batchNumber': batchNumber,
              'responseTime': '${stopwatch.elapsedMilliseconds}ms',
            },
          );
          return true;
        } else {
          throw ApiException(
            data['message'] ?? 'Submission failed',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ApiException(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
          details: {'body': response.body},
        );
      }
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException {
      throw ApiException('Network error occurred');
    } catch (e) {
      if (e is ApiException) rethrow;
      AppLogger.error('Failed to submit batch', details: {'error': e.toString()});
      throw ApiException('Failed to submit batch: ${e.toString()}');
    }
  }
  
  /// Get health status with detailed information
  Future<HealthCheckResponse?> getHealthStatus() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl${Constants.healthEndpoint}'),
            headers: _defaultHeaders,
          )
          .timeout(_timeout);
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HealthCheckResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get health status', details: {'error': e.toString()});
      return null;
    }
  }
}
