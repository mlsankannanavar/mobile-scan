import 'package:freezed_annotation/freezed_annotation.dart';

part 'batch_info.freezed.dart';
part 'batch_info.g.dart';

@freezed
class BatchInfo with _$BatchInfo {
  const factory BatchInfo({
    required String batchNumber,
    required String expiryDate,
    required String itemName,
    required String itemCode,
    required String locationCode,
  }) = _BatchInfo;
  
  factory BatchInfo.fromJson(Map<String, dynamic> json) => _$BatchInfoFromJson(json);
}
