import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class LogsScreen extends StatefulWidget {
  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  LogLevel? _filterLevel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final logs = AppLogger.getLogs();
      setState(() {
        _logs = logs.reversed.toList(); // Show newest first
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AppLogger.error('Failed to load logs: $e');
    }
  }

  List<LogEntry> get _filteredLogs {
    if (_filterLevel == null) return _logs;
    return _logs.where((log) => log.level == _filterLevel).toList();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.debug:
        return Colors.green;
    }
  }

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.debug:
        return Icons.bug_report;
    }
  }

  void _copyLogToClipboard(LogEntry log) {
    final logText = '${log.timestamp.toIso8601String()} [${log.level.name.toUpperCase()}] ${log.message}';
    final detailsText = log.details != null ? '\nDetails: ${log.details.toString()}' : '';
    Clipboard.setData(ClipboardData(text: logText + detailsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Log copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyAllLogsToClipboard() {
    final allLogsText = _filteredLogs
        .map((log) {
          final detailsText = log.details != null ? ' | Details: ${log.details.toString()}' : '';
          return '${log.timestamp.toIso8601String()} [${log.level.name.toUpperCase()}] ${log.message}$detailsText';
        })
        .join('\n');
    
    Clipboard.setData(ClipboardData(text: allLogsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Logs'),
        content: Text('Are you sure you want to clear all logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      AppLogger.clearLogs();
      AppLogger.info('Logs cleared by user');
      _loadLogs();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Application Logs'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          // Filter dropdown
          PopupMenuButton<LogLevel?>(
            initialValue: _filterLevel,
            onSelected: (value) {
              setState(() => _filterLevel = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text('All Logs')),
              PopupMenuItem(value: LogLevel.error, child: Text('Errors Only')),
              PopupMenuItem(value: LogLevel.warning, child: Text('Warnings Only')),
              PopupMenuItem(value: LogLevel.info, child: Text('Info Only')),
              PopupMenuItem(value: LogLevel.debug, child: Text('Debug Only')),
            ],
            icon: Icon(Icons.filter_list),
          ),
          // Copy all logs
          IconButton(
            onPressed: _filteredLogs.isNotEmpty ? _copyAllLogsToClipboard : null,
            icon: Icon(Icons.copy_all),
            tooltip: 'Copy All Logs',
          ),
          // Clear logs
          IconButton(
            onPressed: _logs.isNotEmpty ? _clearLogs : null,
            icon: Icon(Icons.clear_all),
            tooltip: 'Clear Logs',
          ),
          // Refresh logs
          IconButton(
            onPressed: _loadLogs,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Logs',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _filterLevel == null 
                            ? 'No logs available'
                            : 'No ${_filterLevel!.name} logs found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Logs will appear here as you use the app',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Row(
                        children: [
                          Icon(Icons.analytics),
                          SizedBox(width: 8),
                          Text(
                            _filterLevel == null
                                ? 'Total Logs: ${_logs.length}'
                                : '${_filterLevel!.name.toUpperCase()} Logs: ${_filteredLogs.length} of ${_logs.length}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          if (_filteredLogs.isNotEmpty)
                            Text(
                              'Latest: ${_formatTimestamp(_filteredLogs.first.timestamp)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    // Logs list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          final level = log.level;
                          final message = log.message;
                          final timestamp = log.timestamp;

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ExpansionTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(level).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getLevelIcon(level),
                                  color: _getLevelColor(level),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                message,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                _formatTimestamp(timestamp),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    onTap: () => _copyLogToClipboard(log),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy, size: 16),
                                        SizedBox(width: 8),
                                        Text('Copy'),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: Icon(Icons.more_vert, size: 16),
                              ),
                              children: log.details != null ? [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Details:',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          log.details.toString(),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] : [],
                              onExpansionChanged: (expanded) {
                                if (expanded) {
                                  AppLogger.debug('Log details expanded for: ${log.message}');
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _filteredLogs.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Icon(Icons.arrow_upward),
              tooltip: 'Scroll to Top',
            )
          : null,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
