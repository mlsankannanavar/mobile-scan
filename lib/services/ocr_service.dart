import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/logger.dart';

class OCRService {
  TextRecognizer? _textRecognizer;
  
  OCRService() {
    try {
      // Only initialize on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _textRecognizer = TextRecognizer();
        AppLogger.info('OCR Service initialized with Google ML Kit');
      } else {
        AppLogger.info('OCR Service running on unsupported platform');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize TextRecognizer', details: {'error': e.toString()});
      _textRecognizer = null;
    }
  }
  
  void dispose() {
    try {
      _textRecognizer?.close();
    } catch (e) {
      AppLogger.error('Error disposing TextRecognizer', details: {'error': e.toString()});
    }
  }
  
  /// Extract text from image file using Google ML Kit
  Future<String> extractTextFromImage(String imagePath) async {
    if (_textRecognizer == null) {
      throw Exception('OCR Service not available on this platform');
    }

    try {
      AppLogger.info('Starting ML Kit OCR text extraction', details: {'imagePath': imagePath});
      
      final stopwatch = Stopwatch()..start();
      
      // Create input image from file path
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Process image with ML Kit
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      
      stopwatch.stop();
      
      // Extract and preprocess the text
      final rawText = recognizedText.text;
      final cleanedText = _preprocessText(rawText);
      
      AppLogger.info('ML Kit OCR text extraction completed', details: {
        'processingTime': '${stopwatch.elapsedMilliseconds}ms',
        'rawTextLength': rawText.length,
        'cleanedTextLength': cleanedText.length,
        'extractedText': cleanedText.length > 100 
            ? '${cleanedText.substring(0, 100)}...' 
            : cleanedText,
      });
      
      return cleanedText;
    } catch (e) {
      AppLogger.error('ML Kit OCR text extraction failed', details: {
        'error': e.toString(),
        'imagePath': imagePath,
      });
      rethrow;
    }
  }
  
  /// Extract text blocks with bounding boxes
  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    if (_textRecognizer == null) {
      throw Exception('OCR Service not available on this platform');
    }

    try {
      AppLogger.info('Extracting text blocks using Google ML Kit');
      
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      
      return recognizedText.blocks;
    } catch (e) {
      AppLogger.error('Text block extraction failed', details: {'error': e.toString()});
      rethrow;
    }
  }
  
  /// Preprocess extracted text for better matching
  String _preprocessText(String rawText) {
    if (rawText.isEmpty) return rawText;
    
    String text = rawText;
    
    // Convert to uppercase for consistency
    text = text.toUpperCase();
    
    // Remove excessive whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove common OCR artifacts
    text = text.replaceAll(RegExp(r'[^\w\s\-\/\.\:\(\)]'), ' ');
    
    // Clean up common OCR mistakes in batch/lot number contexts
    const replacements = {
      'O': '0', // Common digit confusion
      'I': '1',
      'S': '5',
      'G': '6',
      'B': '8',
    };
    
    // Apply replacements in likely numeric contexts
    for (final entry in replacements.entries) {
      text = text.replaceAllMapped(
        RegExp(r'\b([A-Z]*\d*[A-Z]*)*' + entry.key + r'([A-Z]*\d*[A-Z]*)*\b'),
        (match) {
          final matched = match.group(0)!;
          // Only replace if the context suggests it's a number
          if (RegExp(r'\d').hasMatch(matched)) {
            return matched.replaceAll(entry.key, entry.value);
          }
          return matched;
        },
      );
    }
    
    return text.trim();
  }
  
  /// Extract specific batch information from text
  Map<String, String> extractBatchInfo(String text) {
    final info = <String, String>{};
    
    // Common patterns for batch information
    const patterns = {
      'batchNo': [
        r'BATCH\s*NO?\s*:?\s*([A-Z0-9\-]+)',
        r'BATCH\s*:?\s*([A-Z0-9\-]+)',
        r'B\.?NO?\s*:?\s*([A-Z0-9\-]+)',
      ],
      'lotNo': [
        r'LOT\s*NO?\s*:?\s*([A-Z0-9\-]+)',
        r'LOT\s*:?\s*([A-Z0-9\-]+)',
        r'L\.?NO?\s*:?\s*([A-Z0-9\-]+)',
      ],
      'mfgDate': [
        r'MFG\s*DATE?\s*:?\s*([0-9\/\-\.]+)',
        r'MANUFACTURE\s*DATE?\s*:?\s*([0-9\/\-\.]+)',
        r'MFD\s*:?\s*([0-9\/\-\.]+)',
      ],
      'expDate': [
        r'EXP\s*DATE?\s*:?\s*([0-9\/\-\.]+)',
        r'EXPIRY\s*DATE?\s*:?\s*([0-9\/\-\.]+)',
        r'EXP\s*:?\s*([0-9\/\-\.]+)',
      ],
    };
    
    for (final entry in patterns.entries) {
      final key = entry.key;
      final patternList = entry.value;
      
      for (final pattern in patternList) {
        final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
        if (match != null && match.group(1) != null) {
          info[key] = match.group(1)!.trim();
          break;
        }
      }
    }
    
    AppLogger.info('Extracted batch info', details: info);
    return info;
  }
  
  /// Process batch image and return structured data
  Future<Map<String, String>> processBatchImage(String imagePath) async {
    try {
      final extractedText = await extractTextFromImage(imagePath);
      return extractBatchInfo(extractedText);
    } catch (e) {
      AppLogger.error('Batch image processing failed', details: {
        'error': e.toString(),
        'imagePath': imagePath,
      });
      rethrow;
    }
  }
  
  /// Check if OCR service is available
  bool get isAvailable => _textRecognizer != null;
}
