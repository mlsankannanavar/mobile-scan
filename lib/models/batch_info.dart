class BatchInfo {
  final String batchNumber;
  final String expiryDate;
  final String itemName;
  final String itemCode;
  final String locationCode;

  const BatchInfo({
    required this.batchNumber,
    required this.expiryDate,
    required this.itemName,
    required this.itemCode,
    required this.locationCode,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      batchNumber: json['batchNumber'] ?? json['batch_number'] ?? '',
      expiryDate: json['expiryDate'] ?? json['expiry_date'] ?? '',
      itemName: json['itemName'] ?? json['item_name'] ?? '',
      itemCode: json['itemCode'] ?? json['item_code'] ?? '',
      locationCode: json['locationCode'] ?? json['location_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'batchNumber': batchNumber,
    'expiryDate': expiryDate,
    'itemName': itemName,
    'itemCode': itemCode,
    'locationCode': locationCode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchInfo &&
          runtimeType == other.runtimeType &&
          batchNumber == other.batchNumber &&
          itemCode == other.itemCode;

  @override
  int get hashCode => batchNumber.hashCode ^ itemCode.hashCode;

  @override
  String toString() =>
      'BatchInfo(batch: $batchNumber, item: $itemName, expiry: $expiryDate)';
}
