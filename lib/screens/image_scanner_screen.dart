import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/services.dart';
import '../models/batch_info.dart';
import '../models/match_result.dart';
import '../utils/logger.dart';

class ImageScannerScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ImageScannerScreen> createState() => _ImageScannerScreenState();
}

class _ImageScannerScreenState extends ConsumerState<ImageScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();
  final BackendService _backendService = BackendService();
  final BatchMatcher _batchMatcher = BatchMatcher();
  
  File? _selectedImage;
  bool _isProcessing = false;
  String _extractedText = '';
  List<BatchInfo> _availableBatches = [];
  MatchResult? _matchResult;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    AppLogger.info('[IMAGE_SCANNER] Image scanner screen initialized');
    _loadAvailableBatches();
  }

  Future<void> _loadAvailableBatches() async {
    try {
      AppLogger.info('[IMAGE_SCANNER] Loading available batches from server');
      final batchesMap = await _backendService.getFilteredBatches('mobile_session');
      setState(() {
        _availableBatches = batchesMap.values.toList();
      });
      AppLogger.info('[IMAGE_SCANNER] Loaded ${_availableBatches.length} available batches');
    } catch (e) {
      AppLogger.error('[IMAGE_SCANNER] Failed to load batches: $e');
      setState(() {
        _statusMessage = 'Failed to load batches: $e';
      });
    }
  }

  Future<void> _captureImage() async {
    try {
      AppLogger.info('[IMAGE_SCANNER] Opening camera to capture image');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = '';
          _matchResult = null;
          _statusMessage = '';
        });
        AppLogger.info('[IMAGE_SCANNER] Image captured: ${image.path}');
        await _processImage();
      } else {
        AppLogger.info('[IMAGE_SCANNER] Image capture cancelled by user');
      }
    } catch (e) {
      AppLogger.error('[IMAGE_SCANNER] Failed to capture image: $e');
      setState(() {
        _statusMessage = 'Failed to capture image: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      AppLogger.info('[IMAGE_SCANNER] Opening gallery to select image');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = '';
          _matchResult = null;
          _statusMessage = '';
        });
        AppLogger.info('[IMAGE_SCANNER] Image selected from gallery: ${image.path}');
        await _processImage();
      } else {
        AppLogger.info('[IMAGE_SCANNER] Gallery selection cancelled by user');
      }
    } catch (e) {
      AppLogger.error('[IMAGE_SCANNER] Failed to select image: $e');
      setState(() {
        _statusMessage = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing image with OCR...';
    });

    try {
      AppLogger.info('[IMAGE_SCANNER] Starting OCR processing on image');
      
      // Extract text using OCR
      final extractedText = await _ocrService.extractTextFromImage(_selectedImage!.path);
      
      setState(() {
        _extractedText = extractedText;
        _statusMessage = 'Text extracted, searching for batch matches...';
      });
      
      AppLogger.info('[IMAGE_SCANNER] OCR completed. Extracted text: $extractedText');

      if (extractedText.isNotEmpty && _availableBatches.isNotEmpty) {
        // Convert List<BatchInfo> to Map<String, BatchInfo> for BatchMatcher
        final batchesMap = <String, BatchInfo>{};
        for (final batch in _availableBatches) {
          batchesMap[batch.batchNumber] = batch;
        }
        
        // Find batch matches
        final matchResults = _batchMatcher.findMatches(extractedText, batchesMap);
        
        setState(() {
          _isProcessing = false;
          
          if (matchResults.isNotEmpty) {
            // Get the best match (first one with highest confidence)
            final bestMatch = matchResults.first;
            if (bestMatch.confidence >= 95.0) {
              _statusMessage = 'Exact match found!';
              AppLogger.info('[IMAGE_SCANNER] ✅ Exact match found: ${bestMatch.batchNumber}');
            } else {
              _statusMessage = 'Similar matches found';
              AppLogger.info('[IMAGE_SCANNER] 🔍 Fuzzy matches found: ${matchResults.length}');
            }
            // Store the best match for UI display
            _matchResult = bestMatch;
          } else {
            _statusMessage = 'No matching batches found';
            AppLogger.warn('[IMAGE_SCANNER] ❌ No matches found for extracted text');
          }
        });

        // Submit result to server
        if (matchResults.isNotEmpty) {
          await _submitScanResult(extractedText, matchResults.first);
        }
        
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = extractedText.isEmpty 
              ? 'No text found in image'
              : 'No batches available for matching';
        });
        AppLogger.warn('[IMAGE_SCANNER] Processing completed but no valid data for matching');
      }
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'OCR processing failed: $e';
      });
      AppLogger.error('[IMAGE_SCANNER] OCR processing failed: $e');
    }
  }

  Future<void> _submitScanResult(String extractedText, MatchResult matchResult) async {
    try {
      AppLogger.info('[IMAGE_SCANNER] Submitting scan result to server');
      
      // For now, just log the result since we don't have submitMobileBatch method
      AppLogger.info('[IMAGE_SCANNER] ✅ Scan result logged', details: {
        'extractedText': extractedText,
        'matchFound': matchResult.confidence >= 75.0,
        'batchNumber': matchResult.batchNumber,
        'confidence': matchResult.confidence,
        'scanType': 'image',
      });
      
    } catch (e) {
      AppLogger.error('[IMAGE_SCANNER] Failed to submit scan result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Scanner'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: _loadAvailableBatches,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Batches',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureImage,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('From Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Image Preview
            if (_selectedImage != null) ...[
              Card(
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Text(
                        'Captured Image',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Processing Status
            if (_isProcessing) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Status Message
            if (_statusMessage.isNotEmpty && !_isProcessing) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _matchResult?.confidence != null && _matchResult!.confidence >= 95.0
                            ? Icons.check_circle 
                            : _matchResult?.confidence != null && _matchResult!.confidence >= 75.0
                                ? Icons.search
                                : Icons.info,
                        color: _matchResult?.confidence != null && _matchResult!.confidence >= 95.0
                            ? Colors.green 
                            : _matchResult?.confidence != null && _matchResult!.confidence >= 75.0
                                ? Colors.orange
                                : Colors.blue,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Extracted Text
            if (_extractedText.isNotEmpty) ...[
              Card(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Text(
                        'Extracted Text',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _extractedText,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Match Results
            if (_matchResult != null) ...[
              Card(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _matchResult!.confidence >= 95.0
                            ? Colors.green.shade100
                            : _matchResult!.confidence >= 75.0
                                ? Colors.orange.shade100
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Text(
                        'Match Results',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_matchResult!.confidence >= 95.0) ...[
                            Text(
                              'Exact Match Found:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildBatchCard(_matchResult!.batchInfo, isExact: true),
                          ] else if (_matchResult!.confidence >= 75.0) ...[
                            Text(
                              'Similar Match Found:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildBatchCard(_matchResult!.batchInfo, isExact: false),
                          ] else ...[
                            Text(
                              'Low Confidence Match:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildBatchCard(_matchResult!.batchInfo, isExact: false),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Available Batches Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2),
                    SizedBox(width: 12),
                    Text(
                      'Available Batches: ${_availableBatches.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(BatchInfo batch, {required bool isExact}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExact 
            ? Colors.green.shade50
            : Colors.orange.shade50,
        border: Border.all(
          color: isExact 
              ? Colors.green.shade300
              : Colors.orange.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            batch.batchNumber,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (batch.itemName.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              batch.itemName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (batch.expiryDate.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'Expires: ${batch.expiryDate}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _backendService.dispose();
    super.dispose();
  }
}
