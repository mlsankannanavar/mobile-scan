import 'dart:math';
import '../models/batch_info.dart';
import '../models/match_result.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class BatchMatcher {
  /// Find matches for extracted text in available batches
  List<MatchResult> findMatches(
    String extractedText, 
    Map<String, BatchInfo> availableBatches, {
    double threshold = 75.0,
  }) {
    try {
      AppLogger.info('Starting batch matching', details: {
        'extractedTextLength': extractedText.length,
        'availableBatchesCount': availableBatches.length,
        'threshold': threshold,
      });
      
      final matches = <MatchResult>[];
      final cleanedText = extractedText.toUpperCase();
      
      for (final entry in availableBatches.entries) {
        final batchNumber = entry.key;
        final batchInfo = entry.value;
        
        // Clean batch number (remove parentheses, trim)
        final cleanBatch = _cleanBatchNumber(batchNumber).toUpperCase();
        
        // Step 1: Check for exact match
        if (cleanedText.contains(cleanBatch)) {
          AppLogger.debug('Found exact match: $batchNumber');
          
          // Step 2: Validate with expiry date
          if (_validateExpiryInText(cleanedText, batchInfo.expiryDate)) {
            matches.add(MatchResult(
              batchNumber: batchNumber,
              confidence: 100.0,
              matchType: 'exact',
              batchInfo: batchInfo,
              expiryValidated: true,
            ));
            continue;
          }
        }
        
        // Step 3: Check for fuzzy match using sliding window
        final similarity = _calculateSimilarityInText(cleanBatch, cleanedText);
        if (similarity >= threshold) {
          AppLogger.debug('Found fuzzy match: $batchNumber (${similarity.toStringAsFixed(1)}%)');
          
          // Validate with expiry date
          final expiryValidated = _validateExpiryInText(cleanedText, batchInfo.expiryDate);
          
          matches.add(MatchResult(
            batchNumber: batchNumber,
            confidence: similarity,
            matchType: similarity >= Constants.exactMatchThreshold ? 'exact' : 'fuzzy',
            batchInfo: batchInfo,
            expiryValidated: expiryValidated,
          ));
        }
      }
      
      // Sort by confidence (highest first), then by expiry validation
      matches.sort((a, b) {
        // First sort by expiry validation (validated first)
        if (a.expiryValidated && !b.expiryValidated) return -1;
        if (!a.expiryValidated && b.expiryValidated) return 1;
        
        // Then by confidence
        return b.confidence.compareTo(a.confidence);
      });
      
      // Limit to top matches
      final topMatches = matches.take(Constants.maxAlternativeMatches).toList();
      
      AppLogger.info('Batch matching completed', details: {
        'totalMatches': matches.length,
        'topMatches': topMatches.length,
        'bestMatch': topMatches.isNotEmpty ? topMatches.first.batchNumber : 'none',
        'bestConfidence': topMatches.isNotEmpty ? topMatches.first.confidence : 0,
      });
      
      return topMatches;
    } catch (e) {
      AppLogger.error('Error in batch matching', details: {'error': e.toString()});
      return [];
    }
  }
  
  /// Calculate similarity between two strings using Levenshtein distance
  double calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty && str2.isEmpty) return 100.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    
    final matrix = List.generate(
      str1.length + 1,
      (i) => List.filled(str2.length + 1, 0),
    );
    
    // Initialize first row and column
    for (int i = 0; i <= str1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= str2.length; j++) {
      matrix[0][j] = j;
    }
    
    // Calculate distances
    for (int i = 1; i <= str1.length; i++) {
      for (int j = 1; j <= str2.length; j++) {
        final cost = str1[i - 1] == str2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }
    
    final distance = matrix[str1.length][str2.length];
    final maxLen = max(str1.length, str2.length);
    final similarity = ((1 - distance / maxLen) * 100).roundToDouble();
    
    return similarity;
  }
  
  /// Generate all possible date formats for an expiry date
  List<String> generateDateFormats(String dateStr) {
    try {
      // Parse YYYY-MM-DD format
      final parts = dateStr.split('-');
      if (parts.length != 3) return [];
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final shortYear = year % 100;
      
      // Get month names
      final monthName = _getMonthName(month);
      final monthNameFull = _getMonthNameFull(month);
      
      final formats = <String>[];
      
      // Basic numeric formats
      formats.addAll([
        '$day/$month/$year',     // DD/MM/YYYY
        '$month/$day/$year',     // MM/DD/YYYY
        '$day-$month-$year',     // DD-MM-YYYY
        '$month-$day-$year',     // MM-DD-YYYY
        '$year-$month-$day',     // YYYY-MM-DD
        '$year/$month/$day',     // YYYY/MM/DD
      ]);
      
      // Short year formats
      formats.addAll([
        '$day/$month/$shortYear',     // DD/MM/YY
        '$month/$day/$shortYear',     // MM/DD/YY
        '$day-$month-$shortYear',     // DD-MM-YY
        '$month-$day-$shortYear',     // MM-DD-YY
      ]);
      
      // Month name formats (space separated)
      formats.addAll([
        '$day $monthName $year',      // DD MMM YYYY
        '$monthName $day $year',      // MMM DD YYYY
        '$day $monthNameFull $year',  // DD MMMM YYYY
        '$monthNameFull $day $year',  // MMMM DD YYYY
        '$day $monthName $shortYear', // DD MMM YY
        '$monthName $day $shortYear', // MMM DD YY
      ]);
      
      // Month/Year only
      formats.addAll([
        '$month/$year',       // MM/YYYY
        '$month-$year',       // MM-YYYY
        '$monthName $year',   // MMM YYYY
        '$monthNameFull $year', // MMMM YYYY
        '$month/$shortYear',  // MM/YY
        '$monthName $shortYear', // MMM YY
      ]);
      
      // Dotted formats
      formats.addAll([
        '$day.$month.$year',     // DD.MM.YYYY
        '$day.$month.$shortYear', // DD.MM.YY
        '$year.$month.$day',     // YYYY.MM.DD
      ]);
      
      // Compact (no separators)
      final dayStr = day.toString().padLeft(2, '0');
      final monthStr = month.toString().padLeft(2, '0');
      formats.addAll([
        '$dayStr$monthStr$year',     // DDMMYYYY
        '$dayStr$monthStr$shortYear', // DDMMYY
        '$year$monthStr$dayStr',     // YYYYMMDD
      ]);
      
      // Hyphenated month names
      formats.addAll([
        '$day-$monthName-$year',     // DD-MMM-YYYY
        '$day-$monthName-$shortYear', // DD-MMM-YY
        '$day-$monthNameFull-$year', // DD-MMMM-YYYY
        '$day-$monthNameFull-$shortYear', // DD-MMMM-YY
      ]);
      
      // Add uppercase variations for month names
      final uppercaseFormats = <String>[];
      for (final format in formats) {
        if (format.contains(monthName) || format.contains(monthNameFull)) {
          uppercaseFormats.add(format.toUpperCase());
        }
      }
      formats.addAll(uppercaseFormats);
      
      return formats;
    } catch (e) {
      AppLogger.error('Error generating date formats', details: {
        'dateStr': dateStr,
        'error': e.toString(),
      });
      return [];
    }
  }
  
  /// Validate if expiry date appears in extracted text
  bool validateExpiryInText(String text, String expiryDate) {
    return _validateExpiryInText(text, expiryDate);
  }
  
  /// Clean batch number (remove parentheses, trim)
  String _cleanBatchNumber(String batch) {
    return batch.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
  }
  
  /// Calculate similarity using sliding window approach
  double _calculateSimilarityInText(String batchNo, String text) {
    final batchLen = batchNo.length;
    double bestSimilarity = 0;
    
    // Slide a window of batchLen across the entire text
    for (int i = 0; i <= text.length - batchLen; i++) {
      final textSegment = text.substring(i, i + batchLen);
      final similarity = calculateSimilarity(batchNo, textSegment);
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
      }
    }
    
    return bestSimilarity;
  }
  
  /// Validate if any generated date format appears in text
  bool _validateExpiryInText(String text, String expiryDate) {
    final dateFormats = generateDateFormats(expiryDate);
    
    for (final format in dateFormats) {
      if (text.contains(format.toUpperCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get 3-letter month name
  String _getMonthName(int month) {
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : '';
  }
  
  /// Get full month name
  String _getMonthNameFull(int month) {
    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : '';
  }
}
