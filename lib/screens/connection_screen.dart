import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backend_service.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'qr_scanner_screen.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) => ConnectionStatus.disconnected);
final errorMessageProvider = StateProvider<String?>((ref) => null);
final backendServiceProvider = Provider<BackendService>((ref) => BackendService());

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-test connection on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testConnection();
    });
  }

  Future<void> _testConnection() async {
    final backendService = ref.read(backendServiceProvider);
    
    ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connecting;
    ref.read(errorMessageProvider.notifier).state = null;
    
    try {
      AppLogger.info('Testing server connection...');
      
      final isConnected = await backendService.testConnection();
      
      if (isConnected) {
        ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connected;
        AppLogger.info('Server connection successful');
      } else {
        ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.error;
        ref.read(errorMessageProvider.notifier).state = 'Server connection failed or mobile support not available';
        AppLogger.error('Server connection failed');
      }
    } catch (e) {
      ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.error;
      ref.read(errorMessageProvider.notifier).state = 'Connection error: ${e.toString()}';
      AppLogger.error('Connection test failed', details: {'error': e.toString()});
    }
  }

  void _proceedToScanner() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Constants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              const Icon(
                Icons.qr_code_scanner,
                size: 120,
                color: Color(0xFF2196F3),
              ),
              const SizedBox(height: Constants.largePadding),
              
              Text(
                'BatchMate Scanner',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: Constants.smallPadding),
              
              Text(
                'Mobile Pharmaceutical Batch Scanner',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: Constants.largePadding * 2),
              
              // Connection Status Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(connectionStatus),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(connectionStatus).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _getStatusIcon(connectionStatus),
                  color: Colors.white,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: Constants.defaultPadding),
              
              // Server URL Display
              Container(
                padding: const EdgeInsets.all(Constants.defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Server URL',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Constants.baseUrl,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: Constants.defaultPadding),
              
              // Status Message
              Text(
                _getStatusMessage(connectionStatus),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _getStatusColor(connectionStatus),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (errorMessage != null) ...[
                const SizedBox(height: Constants.smallPadding),
                Container(
                  padding: const EdgeInsets.all(Constants.defaultPadding),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    errorMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              const SizedBox(height: Constants.largePadding),
              
              // Action Buttons
              if (connectionStatus == ConnectionStatus.connecting)
                const CircularProgressIndicator(),
                
              if (connectionStatus == ConnectionStatus.error)
                ElevatedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                
              if (connectionStatus == ConnectionStatus.connected)
                ElevatedButton.icon(
                  onPressed: _proceedToScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Proceed to Scanner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
      case ConnectionStatus.connecting:
        return Icons.cloud_sync;
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }

  String _getStatusMessage(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Not connected';
      case ConnectionStatus.connecting:
        return 'Testing connection...';
      case ConnectionStatus.connected:
        return 'Connected successfully';
      case ConnectionStatus.error:
        return 'Connection failed';
    }
  }
}
