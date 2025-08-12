class Constants {
  // Server Configuration - Local Development
  static const String baseUrl = 'http://localhost:5000';
  static const String healthEndpoint = '/health';
  static const String filteredBatchesEndpoint = '/api/filtered-batches';
  static const String submitMobileBatchEndpoint = '/api/submit-mobile-batch';
  
  // Matching Thresholds
  static const double exactMatchThreshold = 95.0;
  static const double fuzzyMatchThreshold = 75.0;
  static const int maxAlternativeMatches = 4;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  
  // QR Code Settings
  static const String qrCodePrefix = 'BatchMate:';
  
  // OCR Settings
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  
  // Local Storage Keys
  static const String sessionDataKey = 'session_data';
  static const String logsDataKey = 'app_logs';
  static const String settingsKey = 'app_settings';
  
  // Timing Constants
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration qrScanTimeout = Duration(seconds: 30);
  static const Duration ocrProcessingTimeout = Duration(seconds: 15);
  
  // OCR Corrections Mapping (same as server)
  static const Map<String, List<String>> ocrCorrections = {
    'O': ['0', 'Q', 'D'],
    'I': ['1', 'l'],
    'L': ['1', 'I'],
    'S': ['5', '8'],
    'B': ['8', '3'],
    '0': ['O', 'D', '8'],
    'Z': ['2', '7'],
    '6': ['G', 'b'],
    '8': ['B', '3'],
    '9': ['g', 'q'],
    '2': ['Z', 'z'],
    '5': ['S', 's'],
    '1': ['I', 'l', '|'],
  };
  
  // Month Names for Date Parsing
  static const Map<String, int> monthNames = {
    'JAN': 1, 'JANUARY': 1,
    'FEB': 2, 'FEBRUARY': 2,
    'MAR': 3, 'MARCH': 3,
    'APR': 4, 'APRIL': 4,
    'MAY': 5,
    'JUN': 6, 'JUNE': 6,
    'JUL': 7, 'JULY': 7,
    'AUG': 8, 'AUGUST': 8,
    'SEP': 9, 'SEPTEMBER': 9,
    'OCT': 10, 'OCTOBER': 10,
    'NOV': 11, 'NOVEMBER': 11,
    'DEC': 12, 'DECEMBER': 12,
  };
}
