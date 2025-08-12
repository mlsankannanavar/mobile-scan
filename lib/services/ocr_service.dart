import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/logger.dart';

class OCRService {
  late final TextRecognizer _textRecognizer;
  
  OCRService() {
    _textRecognizer = TextRecognizer();
  }
  
  void dispose() {
    _textRecognizer.close();
  }
  
  /// Extract text from image file using ML Kit
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      AppLogger.info('Starting OCR text extraction', details: {
        'imageSize': await imageFile.length(),
        'imagePath': imageFile.path,
      });
      
      final stopwatch = Stopwatch()..start();
      
      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);
      
      // Process the image
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      stopwatch.stop();
      
      // Extract and clean text
      final rawText = recognizedText.text;
      final cleanedText = _preprocessText(rawText);
      
      AppLogger.info('OCR text extraction completed', details: {
        'processingTime': '${stopwatch.elapsedMilliseconds}ms',
        'rawTextLength': rawText.length,
        'cleanedTextLength': cleanedText.length,
        'extractedText': cleanedText.length > 100 
            ? '${cleanedText.substring(0, 100)}...' 
            : cleanedText,
      });
      
      return cleanedText;
    } catch (e) {
      AppLogger.error('OCR text extraction failed', details: {
        'error': e.toString(),
        'imageFile': imageFile.path,
      });
      rethrow;
    }
  }
  
  /// Extract text blocks with confidence (for debugging)
  Future<List<TextBlock>> extractTextBlocks(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.blocks;
    } catch (e) {
      AppLogger.error('Text block extraction failed', details: {'error': e.toString()});
      return [];
    }
  }
  
  /// Preprocess extracted text (same logic as server)
  String _preprocessText(String rawText) {
    if (rawText.isEmpty) return rawText;
    
    String text = rawText;
    
    // Convert to uppercase for consistency
    text = text.toUpperCase();
    
    // Remove excessive whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove common OCR artifacts
    text = text.replaceAll(RegExp(r'[^\w\s\/\-\.\:\(\)]'), ' ');
    
    // Normalize common separators
    text = text.replaceAll(RegExp(r'\s*\/\s*'), '/');
    text = text.replaceAll(RegExp(r'\s*\-\s*'), '-');
    text = text.replaceAll(RegExp(r'\s*\.\s*'), '.');
    text = text.replaceAll(RegExp(r'\s*\:\s*'), ':');
    
    // Apply OCR corrections for common misreadings
    text = _applyOCRCorrections(text);
    
    return text.trim();
  }
  
  /// Apply OCR corrections for common character misreadings
  String _applyOCRCorrections(String text) {
    String correctedText = text;
    
    // Apply common OCR corrections based on context
    // These are applied more conservatively than server-side variations
    
    // Common number/letter confusions in batch numbers
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'\b([A-Z]*[0-9]*)[O]([0-9]+)\b'),
      (match) => '${match.group(1)}0${match.group(2)}', // O -> 0 in numeric context
    );
    
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'\b([A-Z]*[0-9]*)[I|l]([0-9]+)\b'),
      (match) => '${match.group(1)}1${match.group(2)}', // I/l -> 1 in numeric context
    );
    
    // Date context corrections
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'\b([0-9]{1,2})[O]([0-9]{1,2})[O]([0-9]{2,4})\b'),
      (match) => '${match.group(1)}0${match.group(2)}0${match.group(3)}', // O -> 0 in dates
    );
    
    return correctedText;
  }
  
  /// Check if ML Kit is available on the device
  static Future<bool> isAvailable() async {
    try {
      final recognizer = TextRecognizer();
      await recognizer.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
