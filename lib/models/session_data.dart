import 'package:freezed_annotation/freezed_annotation.dart';
import 'batch_info.dart';

part 'session_data.freezed.dart';
part 'session_data.g.dart';

@freezed
class SessionData with _$SessionData {
  const factory SessionData({
    required String sessionId,
    required Map<String, BatchInfo> availableBatches,
    required String locationCode,
    required List<String> itemCodes,
    required DateTime downloadTimestamp,
    @Default(0) int batchCount,
  }) = _SessionData;
  
  factory SessionData.fromJson(Map<String, dynamic> json) => _$SessionDataFromJson(json);
}
