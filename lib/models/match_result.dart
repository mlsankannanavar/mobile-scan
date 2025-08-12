import 'batch_info.dart';

class MatchResult {
  final String batchNumber;
  final double confidence;
  final String matchType; // 'exact', 'fuzzy', 'partial'
  final BatchInfo batchInfo;
  final String? foundDateFormat;
  final bool expiryValidated;

  const MatchResult({
    required this.batchNumber,
    required this.confidence,
    required this.matchType,
    required this.batchInfo,
    this.foundDateFormat,
    this.expiryValidated = false,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      batchNumber: json['batchNumber'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      matchType: json['matchType'] ?? 'none',
      batchInfo: BatchInfo.fromJson(json['batchInfo'] ?? {}),
      foundDateFormat: json['foundDateFormat'],
      expiryValidated: json['expiryValidated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'batchNumber': batchNumber,
    'confidence': confidence,
    'matchType': matchType,
    'batchInfo': batchInfo.toJson(),
    'foundDateFormat': foundDateFormat,
    'expiryValidated': expiryValidated,
  };

  MatchResult copyWith({
    String? batchNumber,
    double? confidence,
    String? matchType,
    BatchInfo? batchInfo,
    String? foundDateFormat,
    bool? expiryValidated,
  }) {
    return MatchResult(
      batchNumber: batchNumber ?? this.batchNumber,
      confidence: confidence ?? this.confidence,
      matchType: matchType ?? this.matchType,
      batchInfo: batchInfo ?? this.batchInfo,
      foundDateFormat: foundDateFormat ?? this.foundDateFormat,
      expiryValidated: expiryValidated ?? this.expiryValidated,
    );
  }

  @override
  String toString() => 
      'MatchResult(batch: $batchNumber, confidence: ${(confidence * 100).toStringAsFixed(1)}%, type: $matchType)';
}
