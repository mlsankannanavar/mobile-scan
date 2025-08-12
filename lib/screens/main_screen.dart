import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backend_service.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'qr_scanner_screen.dart';
import 'logs_screen.dart';
import 'image_scanner_screen.dart';

final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) => ConnectionStatus.disconnected);

enum ConnectionStatus { disconnected, connecting, connected, error }

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final BackendService _backendService = BackendService();
  String _statusMessage = 'Not connected to server';
  String _serverInfo = '';

  @override
  void initState() {
    super.initState();
    AppLogger.info('[MAIN] Main screen initialized');
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connecting;
      _statusMessage = 'Testing connection...';
    });

    AppLogger.info('[MAIN] Starting connection test to server: ${Constants.baseUrl}');

    try {
      final isConnected = await _backendService.testConnection();
      
      if (isConnected) {
        setState(() {
          ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connected;
          _statusMessage = 'Connected to server successfully';
          _serverInfo = 'Server: ${Constants.baseUrl}\nMobile API: Ready';
        });
        AppLogger.info('[MAIN] ✅ Server connection successful');
      } else {
        setState(() {
          ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.error;
          _statusMessage = 'Failed to connect to server';
          _serverInfo = 'Please check server status';
        });
        AppLogger.error('[MAIN] ❌ Server connection failed');
      }
    } catch (e) {
      setState(() {
        ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.error;
        _statusMessage = 'Connection error: ${e.toString()}';
        _serverInfo = 'Please check network and server';
      });
      AppLogger.error('[MAIN] ❌ Connection error: $e');
    }
  }

  void _navigateToQRScanner() {
    AppLogger.info('[MAIN] Navigating to QR Scanner');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen()),
    );
  }

  void _navigateToImageScanner() {
    AppLogger.info('[MAIN] Navigating to Image Scanner');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImageScannerScreen()),
    );
  }

  void _showLogsScreen() {
    AppLogger.info('[MAIN] Opening logs screen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LogsScreen()),
    );
  }

  Color _getStatusColor() {
    switch (ref.watch(connectionStatusProvider)) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (ref.watch(connectionStatusProvider)) {
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.error:
        return Icons.error;
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BatchMate Scanner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          // Logs button on right edge
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _showLogsScreen,
              icon: Icon(Icons.list_alt, size: 28),
              tooltip: 'View Logs',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: Icon(
                            _getStatusIcon(),
                            key: ValueKey(connectionStatus),
                            color: _getStatusColor(),
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Server Status',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (connectionStatus != ConnectionStatus.connecting)
                          IconButton(
                            onPressed: _testConnection,
                            icon: Icon(Icons.refresh),
                            tooltip: 'Retry Connection',
                          ),
                      ],
                    ),
                    if (_serverInfo.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _serverInfo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Scanning Options Section
            Text(
              'Scanning Options',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // QR Scanner Card
            Card(
              elevation: 2,
              child: InkWell(
                onTap: isConnected ? _navigateToQRScanner : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: isConnected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Scan QR Code',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isConnected 
                            ? null
                            : Theme.of(context).disabledColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Scan batch QR codes for instant lookup',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isConnected 
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).disabledColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Image Scanner Card
            Card(
              elevation: 2,
              child: InkWell(
                onTap: isConnected ? _navigateToImageScanner : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 48,
                        color: isConnected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Scan Image',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isConnected 
                            ? null
                            : Theme.of(context).disabledColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Capture batch label images for OCR processing',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isConnected 
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).disabledColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (!isConnected) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connect to server to enable scanning features',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backendService.dispose();
    super.dispose();
  }
}
