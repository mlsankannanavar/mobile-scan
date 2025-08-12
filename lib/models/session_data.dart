import 'batch_info.dart';

class SessionData {
  final String sessionId;
  final Map<String, BatchInfo> availableBatches;
  final String locationCode;
  final List<String> itemCodes;
  final DateTime downloadTimestamp;
  final int batchCount;

  const SessionData({
    required this.sessionId,
    required this.availableBatches,
    required this.locationCode,
    required this.itemCodes,
    required this.downloadTimestamp,
    this.batchCount = 0,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    final batchesJson = json['availableBatches'] as Map<String, dynamic>? ?? {};
    final batches = <String, BatchInfo>{};
    
    for (final entry in batchesJson.entries) {
      batches[entry.key] = BatchInfo.fromJson(entry.value);
    }

    return SessionData(
      sessionId: json['sessionId'] ?? '',
      availableBatches: batches,
      locationCode: json['locationCode'] ?? '',
      itemCodes: List<String>.from(json['itemCodes'] ?? []),
      downloadTimestamp: DateTime.parse(
        json['downloadTimestamp'] ?? DateTime.now().toIso8601String()
      ),
      batchCount: json['batchCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final batchesJson = <String, dynamic>{};
    for (final entry in availableBatches.entries) {
      batchesJson[entry.key] = entry.value.toJson();
    }

    return {
      'sessionId': sessionId,
      'availableBatches': batchesJson,
      'locationCode': locationCode,
      'itemCodes': itemCodes,
      'downloadTimestamp': downloadTimestamp.toIso8601String(),
      'batchCount': batchCount,
    };
  }

  SessionData copyWith({
    String? sessionId,
    Map<String, BatchInfo>? availableBatches,
    String? locationCode,
    List<String>? itemCodes,
    DateTime? downloadTimestamp,
    int? batchCount,
  }) {
    return SessionData(
      sessionId: sessionId ?? this.sessionId,
      availableBatches: availableBatches ?? this.availableBatches,
      locationCode: locationCode ?? this.locationCode,
      itemCodes: itemCodes ?? this.itemCodes,
      downloadTimestamp: downloadTimestamp ?? this.downloadTimestamp,
      batchCount: batchCount ?? this.batchCount,
    );
  }

  @override
  String toString() => 
      'SessionData(id: $sessionId, batches: ${availableBatches.length}, location: $locationCode)';
}
