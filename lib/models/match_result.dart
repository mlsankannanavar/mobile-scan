import 'package:freezed_annotation/freezed_annotation.dart';
import 'batch_info.dart';

part 'match_result.freezed.dart';
part 'match_result.g.dart';

@freezed
class MatchResult with _$MatchResult {
  const factory MatchResult({
    required String batchNumber,
    required double confidence,
    required String matchType, // 'exact', 'fuzzy', 'partial'
    required BatchInfo batchInfo,
    String? foundDateFormat,
    @Default(false) bool expiryValidated,
  }) = _MatchResult;
  
  factory MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);
}
