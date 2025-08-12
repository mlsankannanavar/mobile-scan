import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    AppLogger.info('QR Scanner screen opened');
  }

  void _simulateQRScan() {
    // This is a placeholder for QR scanning functionality
    // In a real implementation, this would use qr_code_scanner package
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
            if (scannedSessionId == null) ...[
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
                    ElevatedButton.icon(
                      onPressed: _simulateQRScan,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Simulate QR Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
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
