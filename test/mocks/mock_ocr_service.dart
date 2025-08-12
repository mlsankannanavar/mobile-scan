// Mock OCR Service for testing
class MockOCRService {
  MockOCRService();
  
  void dispose() {}
  
  Future<String> extractTextFromImage(String imagePath) async {
    return 'BATCH: TEST123\nLOT: L123456\nMFG: 01/2024\nEXP: 01/2026';
  }
  
  Future<List<String>> extractTextBlocks(String imagePath) async {
    return [
      'BATCH: TEST123',
      'LOT: L123456', 
      'MFG: 01/2024',
      'EXP: 01/2026'
    ];
  }
  
  Map<String, String> extractBatchInfo(String text) {
    return {
      'batchNo': 'TEST123',
      'lotNo': 'L123456',
      'mfgDate': '01/2024',
      'expDate': '01/2026',
    };
  }
  
  Future<Map<String, String>> processBatchImage(String imagePath) async {
    return {
      'batchNo': 'TEST123',
      'lotNo': 'L123456',
      'mfgDate': '01/2024',
      'expDate': '01/2026',
    };
  }
}
