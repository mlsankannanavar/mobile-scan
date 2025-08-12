import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  String? scannedSessionId;
  bool isLoading = false;
  bool showScanner = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    AppLogger.info('QR Scanner screen opened');
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _startQRScan() {
    setState(() {
      showScanner = true;
    });
  }

  void _onQRDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && scannedSessionId == null) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          scannedSessionId = code;
          showScanner = false;
        });
        
        AppLogger.info('QR Code scanned', details: {
          'sessionId': code,
        });
        
        _downloadBatchData();
      }
    }
  }

  void _simulateQRScan() {
    // Fallback simulation for testing
    setState(() {
      scannedSessionId = 'TEST_SESSION_${DateTime.now().millisecondsSinceEpoch}';
    });
    
    AppLogger.info('QR Code scanned (simulated)', details: {
      'sessionId': scannedSessionId,
    });
    
    _downloadBatchData();
  }

  void _downloadBatchData() async {
    setState(() {
      isLoading = true;
    });
    
    AppLogger.info('Starting batch data download for session: $scannedSessionId');
    
    // Simulate download delay
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      isLoading = false;
    });
    
    AppLogger.info('Batch data download completed');
    
    // Navigate to camera screen (placeholder)
    _showCameraScreen();
  }

  void _showCameraScreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ready to scan! Camera screen would open here.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Constants.defaultPadding),
        child: Column(
          children: [
            if (showScanner) ...[
              // Real QR Scanner
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Scan QR Code',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Constants.defaultPadding),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: MobileScanner(
                            controller: cameraController,
                            onDetect: _onQRDetected,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Constants.defaultPadding),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                showScanner = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: Constants.defaultPadding),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _simulateQRScan,
                            icon: const Icon(Icons.science),
                            label: const Text('Simulate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (scannedSessionId == null) ...[
              // QR Scanner Instructions
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: Constants.largePadding),
                    Text(
                      'Scan QR Code',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Constants.smallPadding),
                    Text(
                      'Point your camera at the QR code from the browser extension',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Constants.largePadding),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startQRScan,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan QR Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: Constants.defaultPadding),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _simulateQRScan,
                            icon: const Icon(Icons.science),
                            label: const Text('Simulate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Session Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Constants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: Constants.smallPadding),
                          Text(
                            'QR Code Scanned',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Constants.smallPadding),
                      Text(
                        'Session ID: $scannedSessionId',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: Constants.defaultPadding),
              
              // Download Progress
              if (isLoading) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Constants.defaultPadding),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: Constants.defaultPadding),
                        Text(
                          'Downloading batch data...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: Constants.smallPadding),
                        Text(
                          'This may take a few moments',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Ready to Scan
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(Constants.defaultPadding),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.download_done,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: Constants.defaultPadding),
                        Text(
                          'Ready to Scan Batches!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: Constants.smallPadding),
                        Text(
                          'Batch data downloaded successfully.\nTap the button below to start scanning.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Constants.defaultPadding),
                        ElevatedButton.icon(
                          onPressed: _showCameraScreen,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Start Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}
